<?php
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Get form data
    $name = isset($_POST['name']) ? htmlspecialchars(trim($_POST['name'])) : '';
    $email = isset($_POST['email']) ? htmlspecialchars(trim($_POST['email'])) : '';
    $message = isset($_POST['message']) ? htmlspecialchars(trim($_POST['message'])) : '';
    
    // Validate required fields
    if (empty($name) || empty($email) || empty($message)) {
        header("Location: index.php?error=1");
        exit();
    }
    
    // Validate email format
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        header("Location: index.php?error=2");
        exit();
    }
    
    // Process the data (you can save to file, database, or send email here)
    $timestamp = date('Y-m-d H:i:s');
    $log_entry = "[$timestamp] Name: $name, Email: $email, Message: $message" . PHP_EOL;
    
    // Log to a file (ensure directory is writable)
    file_put_contents('/var/www/html/form-submissions.log', $log_entry, FILE_APPEND | LOCK_EX);
    
    // Redirect back to form with success message
    header("Location: index.php?success=1");
    exit();
} else {
    // If not POST request, redirect to form
    header("Location: index.php");
    exit();
}
?>
