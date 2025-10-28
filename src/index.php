<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web Form</title>
    <link rel="stylesheet" type="text/css" href="styles.css">
</head>
<body>
    <div class="container">
        <h2>Contact Fahad</h2>
        <form action="process-form.php" method="POST">
            <div class="form-group">
                <input type="text" name="name" placeholder="Your Name" required>
            </div>
            <div class="form-group">
                <input type="email" name="email" placeholder="Your Email" required>
            </div>
            <div class="form-group">
                <textarea name="message" placeholder="Your Message" rows="5" required></textarea>
            </div>
            <button type="submit">Submit</button>
        </form>
        <?php
        // Display success message if redirected from process-form
        if (isset($_GET['success']) && $_GET['success'] == '1') {
             '<div class="success-message">Thank you! Your message has been received.</div>';
        }
        ?>
    </div>
</body>
</html>
