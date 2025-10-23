<?php
/**
 * Fish Care - Authentication API
 * api/auth.php
 */

require_once '../config.php';

header('Content-Type: application/json; charset=utf-8');

$database = new Database();
$conn = $database->connect();

$action = isset($_GET['action']) ? $_GET['action'] : '';

switch($action) {
    case 'login':
        login($conn);
        break;
    case 'register':
        register($conn);
        break;
    case 'logout':
        logout();
        break;
    case 'check_session':
        check_session();
        break;
    default:
        json_response('error', 'Invalid action', null);
}

// Login Function 
function login($conn) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        json_response('error', 'Invalid request method', null);
    }

    $mobile = isset($_POST['mobile']) ? sanitize_input($_POST['mobile']) : '';
    $password = isset($_POST['password']) ? $_POST['password'] : '';
    $user_type = isset($_POST['user_type']) ? sanitize_input($_POST['user_type']) : '';

    if (empty($mobile) || empty($password) || empty($user_type)) {
        json_response('error', 'সকল ফিল্ড পূরণ করুন', null);
    }

    try {
        $query = "SELECT id, user_type, name, mobile, password, division, district, upazila, status 
                  FROM users 
                  WHERE mobile = :mobile AND user_type = :user_type";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':mobile', $mobile);
        $stmt->bindParam(':user_type', $user_type);
        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            $user = $stmt->fetch();
            
            if ($user['status'] !== 'active') {
                json_response('error', 'আপনার একাউন্টটি নিষ্ক্রিয় রয়েছে', null);
            }

            // Verify password
            if (password_verify($password, $user['password'])) {
                // Start session
                session_start();
                $_SESSION['user_id'] = $user['id'];
                $_SESSION['user_type'] = $user['user_type'];
                $_SESSION['name'] = $user['name'];
                $_SESSION['mobile'] = $user['mobile'];
                $_SESSION['division'] = $user['division'];
                $_SESSION['district'] = $user['district'];
                $_SESSION['upazila'] = $user['upazila'];

                // Prepare user data to return
                $userData = [
                    'id' => $user['id'],
                    'user_type' => $user['user_type'],
                    'name' => $user['name'],
                    'mobile' => $user['mobile'],
                    'division' => $user['division'],
                    'district' => $user['district'],
                    'upazila' => $user['upazila']
                ];

                json_response('success', 'লগইন সফল হয়েছে', $userData);
            } else {
                json_response('error', 'মোবাইল নম্বর অথবা পাসওয়ার্ড ভুল', null);
            }
        } else {
            json_response('error', 'মোবাইল নম্বর অথবা পাসওয়ার্ড ভুল', null);
        }
    } catch(PDOException $e) {
        json_response('error', 'Database error: ' . $e->getMessage(), null);
    }
}

// Register Function
function register($conn) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        json_response('error', 'Invalid request method', null);
    }

    $user_type = sanitize_input($_POST['user_type'] ?? '');
    $name = sanitize_input($_POST['name'] ?? '');
    $mobile = sanitize_input($_POST['mobile'] ?? '');
    $password = $_POST['password'] ?? '';
    $email = sanitize_input($_POST['email'] ?? '');
    $division = sanitize_input($_POST['division'] ?? '');
    $district = sanitize_input($_POST['district'] ?? '');
    $upazila = sanitize_input($_POST['upazila'] ?? '');
    $address = sanitize_input($_POST['address'] ?? '');

    // Validation
    if (empty($user_type) || empty($name) || empty($mobile) || empty($password)) {
        json_response('error', 'সকল আবশ্যক ফিল্ড পূরণ করুন', null);
    }

    if (!preg_match('/^01[0-9]{9}$/', $mobile)) {
        json_response('error', 'সঠিক মোবাইল নম্বর দিন', null);
    }

    if (strlen($password) < 6) {
        json_response('error', 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে', null);
    }

    try {
        // Check if mobile already exists
        $checkQuery = "SELECT id FROM users WHERE mobile = :mobile";
        $checkStmt = $conn->prepare($checkQuery);
        $checkStmt->bindParam(':mobile', $mobile);
        $checkStmt->execute();

        if ($checkStmt->rowCount() > 0) {
            json_response('error', 'এই মোবাইল নম্বর দিয়ে ইতিমধ্যে একাউন্ট আছে', null);
        }

        // Hash password
        $hashed_password = password_hash($password, PASSWORD_DEFAULT);

        // Insert user
        $query = "INSERT INTO users (user_type, name, mobile, password, email, division, district, upazila, address) 
                  VALUES (:user_type, :name, :mobile, :password, :email, :division, :district, :upazila, :address)";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_type', $user_type);
        $stmt->bindParam(':name', $name);
        $stmt->bindParam(':mobile', $mobile);
        $stmt->bindParam(':password', $hashed_password);
        $stmt->bindParam(':email', $email);
        $stmt->bindParam(':division', $division);
        $stmt->bindParam(':district', $district);
        $stmt->bindParam(':upazila', $upazila);
        $stmt->bindParam(':address', $address);

        if ($stmt->execute()) {
            json_response('success', 'একাউন্ট তৈরি সফল হয়েছে', ['user_id' => $conn->lastInsertId()]);
        } else {
            json_response('error', 'একাউন্ট তৈরি করা যায়নি', null);
        }
    } catch(PDOException $e) {
        json_response('error', 'Database error: ' . $e->getMessage(), null);
    }
}

// Logout Function
function logout() {
    session_start();
    session_unset();
    session_destroy();
    json_response('success', 'লগআউট সফল হয়েছে', null);
}

// Check Session Function
function check_session() {
    session_start();
    if (isset($_SESSION['user_id'])) {
        $userData = [
            'id' => $_SESSION['user_id'],
            'user_type' => $_SESSION['user_type'],
            'name' => $_SESSION['name'],
            'mobile' => $_SESSION['mobile']
        ];
        json_response('success', 'Session active', $userData);
    } else {
        json_response('error', 'No active session', null);
    }
}

?>
