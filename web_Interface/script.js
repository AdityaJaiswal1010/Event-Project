function generateQRCode() {
    const candidate_name = document.getElementById('candidate_name').value;
    const dob = document.getElementById('dob').value;
    const father_name= document.getElementById('father_name').value;
    const mother_name= document.getElementById('mother_name').value;

    if (candidate_name && dob && father_name && mother_name) {
        const qrData = JSON.stringify({ candidate_name, dob, father_name, mother_name });
        const qrCodeElement = document.getElementById('qrcode');
        qrCodeElement.innerHTML = "";
        new QRCode(qrCodeElement, qrData);
        // sendEmail(email, qrData);
    }
}

function sendEmail(to, qrData) {
    const senderEmail = 'aditya.jaiswal15974@sakec.ac.in';
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
