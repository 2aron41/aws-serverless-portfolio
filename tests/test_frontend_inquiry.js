"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");

const APP_SOURCE = fs.readFileSync(
  "website/app.js",
  "utf8",
);

function deferred() {
  let resolve;
  let reject;

  const promise = new Promise((res, rej) => {
    resolve = res;
    reject = rej;
  });

  return {
    promise,
    resolve,
    reject,
  };
}

function createHarness({
  valid = true,
  values = {
    name: "Day 37 Tester",
    email: "day37@example.com",
    message: "This is a valid Day 37 test message.",
  },
  fetchImpl = async () => ({
    ok: true,
  }),
} = {}) {
  let submitHandler = null;
  let reportValidityCalls = 0;
  let resetCalls = 0;
  const fetchCalls = [];

  const form = {
    checkValidity() {
      return valid;
    },

    reportValidity() {
      reportValidityCalls += 1;
    },

    reset() {
      resetCalls += 1;
    },

    addEventListener(type, handler) {
      if (type === "submit") {
        submitHandler = handler;
      }
    },
  };

  const button = {
    disabled: false,
  };

  const status = {
    textContent: "",
  };

  class MockFormData {
    constructor(receivedForm) {
      assert.equal(
        receivedForm,
        form,
        "FormData should receive the inquiry form.",
      );
    }

    get(name) {
      return values[name];
    }
  }

  async function mockFetch(...args) {
    fetchCalls.push(args);
    return fetchImpl(...args);
  }

  const document = {
    querySelector(selector) {
      switch (selector) {
        case "#inquiry-form":
          return form;
        case "#inquiry-submit":
          return button;
        case "#inquiry-status":
          return status;
        default:
          throw new Error(`Unexpected selector: ${selector}`);
      }
    },
  };

  const context = vm.createContext({
    document,
    FormData: MockFormData,
    fetch: mockFetch,
    Error,
    JSON,
  });

  vm.runInContext(
    APP_SOURCE,
    context,
    {
      filename: "website/app.js",
    },
  );

  assert.equal(
    typeof submitHandler,
    "function",
    "Submit listener should be registered.",
  );

  async function submit() {
    let prevented = false;

    const event = {
      preventDefault() {
        prevented = true;
      },
    };

    await submitHandler(event);

    assert.equal(
      prevented,
      true,
      "Form submission should prevent default navigation.",
    );
  }

  return {
    form,
    button,
    status,
    fetchCalls,
    submit,
    get reportValidityCalls() {
      return reportValidityCalls;
    },
    get resetCalls() {
      return resetCalls;
    },
  };
}

async function testNativeInvalidFormDoesNotFetch() {
  const harness = createHarness({
    valid: false,
  });

  await harness.submit();

  assert.equal(harness.fetchCalls.length, 0);
  assert.equal(harness.reportValidityCalls, 1);
  assert.equal(harness.button.disabled, false);
}

async function testTrimmedInvalidValuesDoNotFetch() {
  const harness = createHarness({
    values: {
      name: "   ",
      email: "a@b.com",
      message: "          ",
    },
  });

  await harness.submit();

  assert.equal(harness.fetchCalls.length, 0);

  assert.equal(
    harness.status.textContent,
    "Please complete all fields with valid information.",
  );

  assert.equal(harness.button.disabled, false);
  assert.equal(harness.resetCalls, 0);
}

async function testSuccessfulSubmission() {
  const request = deferred();

  const harness = createHarness({
    values: {
      name: "  Day 37 Tester  ",
      email: "  day37@example.com  ",
      message: "  This is a controlled frontend test message.  ",
    },

    fetchImpl() {
      return request.promise;
    },
  });

  const submission = harness.submit();

  await Promise.resolve();

  assert.equal(
    harness.button.disabled,
    true,
    "Submit button should disable while request is pending.",
  );

  assert.equal(
    harness.status.textContent,
    "Sending message...",
  );

  assert.equal(harness.fetchCalls.length, 1);

  const [endpoint, options] = harness.fetchCalls[0];

  assert.equal(
    endpoint,
    "https://2v4ijd6eta.execute-api.us-east-1.amazonaws.com/inquiries",
  );

  assert.equal(options.method, "POST");

  assert.equal(
    options.headers["Content-Type"],
    "application/json",
  );

  assert.deepEqual(
    Object.keys(options.headers),
    ["Content-Type"],
  );

  assert.deepEqual(
    JSON.parse(options.body),
    {
      name: "Day 37 Tester",
      email: "day37@example.com",
      message: "This is a controlled frontend test message.",
    },
  );

  request.resolve({
    ok: true,
  });

  await submission;

  assert.equal(harness.button.disabled, false);
  assert.equal(harness.resetCalls, 1);

  assert.equal(
    harness.status.textContent,
    "Message sent successfully. Thank you for reaching out.",
  );
}

async function testHttpFailureShowsGenericError() {
  const harness = createHarness({
    fetchImpl: async () => ({
      ok: false,
    }),
  });

  await harness.submit();

  assert.equal(harness.fetchCalls.length, 1);
  assert.equal(harness.resetCalls, 0);
  assert.equal(harness.button.disabled, false);

  assert.equal(
    harness.status.textContent,
    "Your message could not be sent. Please try again later.",
  );
}

async function testNetworkFailureShowsGenericError() {
  const harness = createHarness({
    fetchImpl: async () => {
      throw new Error("simulated network failure");
    },
  });

  await harness.submit();

  assert.equal(harness.fetchCalls.length, 1);
  assert.equal(harness.resetCalls, 0);
  assert.equal(harness.button.disabled, false);

  assert.equal(
    harness.status.textContent,
    "Your message could not be sent. Please try again later.",
  );
}

async function main() {
  const tests = [
    [
      "native invalid form blocks fetch",
      testNativeInvalidFormDoesNotFetch,
    ],
    [
      "trimmed invalid values block fetch",
      testTrimmedInvalidValuesDoNotFetch,
    ],
    [
      "successful submission trims payload and resets form",
      testSuccessfulSubmission,
    ],
    [
      "HTTP failure returns generic UI error",
      testHttpFailureShowsGenericError,
    ],
    [
      "network failure returns generic UI error",
      testNetworkFailureShowsGenericError,
    ],
  ];

  for (const [name, test] of tests) {
    await test();
    console.log(`PASS: ${name}`);
  }

  console.log();
  console.log(
    `Success! ${tests.length} passed, 0 failed.`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
