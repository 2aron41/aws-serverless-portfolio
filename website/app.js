"use strict";

const INQUIRY_API_ENDPOINT =
  "https://2v4ijd6eta.execute-api.us-east-1.amazonaws.com/inquiries";

const inquiryForm = document.querySelector("#inquiry-form");
const submitButton = document.querySelector("#inquiry-submit");
const statusMessage = document.querySelector("#inquiry-status");

const SUBMISSION_COOLDOWN_MS = 30_000;
let lastSuccessfulSubmissionAt = null;

async function submitInquiry(event) {
  event.preventDefault();

  if (!inquiryForm.checkValidity()) {
    inquiryForm.reportValidity();
    return;
  }

  const formData = new FormData(inquiryForm);

  const inquiry = {
    name: formData.get("name").trim(),
    email: formData.get("email").trim(),
    message: formData.get("message").trim(),
  };

  if (
    inquiry.name.length < 2 ||
    inquiry.email.length < 3 ||
    inquiry.message.length < 10
  ) {
    statusMessage.textContent =
      "Please complete all fields with valid information.";
    return;
  }

  if (
    lastSuccessfulSubmissionAt !== null &&
    Date.now() - lastSuccessfulSubmissionAt < SUBMISSION_COOLDOWN_MS
  ) {
    statusMessage.textContent =
      "Please wait before sending another message.";
    return;
  }

  submitButton.disabled = true;
  statusMessage.textContent = "Sending message...";

  try {
    const response = await fetch(INQUIRY_API_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(inquiry),
    });

    if (!response.ok) {
      throw new Error("Inquiry request failed.");
    }

    inquiryForm.reset();
    lastSuccessfulSubmissionAt = Date.now();

    statusMessage.textContent =
      "Message sent successfully. Thank you for reaching out.";
  } catch {
    statusMessage.textContent =
      "Your message could not be sent. Please try again later.";
  } finally {
    submitButton.disabled = false;
  }
}

inquiryForm.addEventListener("submit", submitInquiry);
