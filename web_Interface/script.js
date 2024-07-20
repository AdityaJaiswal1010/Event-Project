function generateQRCode() {
    const name = document.getElementById('name').value;
    const email = document.getElementById('email').value;

    if (name && email) {
        const qrData = JSON.stringify({ name, email });
        const qrCodeElement = document.getElementById('qrcode');
        qrCodeElement.innerHTML = "";
        new QRCode(qrCodeElement, qrData);
        sendEmail(email, qrData);
    }
}

function sendEmail(to, qrData) {
    const senderEmail = 'adityajaiswal9820@gmail.com';
    const senderPassword = to;  // Use app-specific password if using Gmail
    const emailBody = `Here is your QR code data: ${qrData}`;

    Email.send({
        SecureToken: "50903A8F9EE0C1B0434139A892C2AE45113C", // Use SMTP.js secure token or SMTP credentials
        To: to,
        From: senderEmail,
        Subject: "Your QR Code",
        Body: emailBody
    }).then(
        message => alert("Mail sent successfully")
    ).catch(
        error => alert("Failed to send mail: " + error)
    );
}
