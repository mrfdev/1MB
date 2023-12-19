<?php
if (!defined('INCLUDED')) {
  header('HTTP/1.0 403 Forbidden');
  exit('Direct access not allowed');
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="description" content="1moreblock.com Groups for Minecraft server">
  <meta name="author" content="1moreblock.com - Floris Fiedeldij Dop">
  <title>Player Groups - 1MoreBlock.com</title>
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <!-- key/value for group-titles -->
  <?php include 'includes/groups.php'; ?>

  <!-- Navigation -->
  <nav class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top">
    <a class="navbar-brand" href="index.php">1MoreBlock.com</a>
    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarResponsive" aria-controls="navbarResponsive" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navbarResponsive">
      <ul class="navbar-nav ml-auto">
        <li class="nav-item active">
          <a class="nav-link" href="index.php">GROUPS
            <span class="sr-only">(current)</span>
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="https://omgboards.com/vote/">Voting</a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="https://omgboards.com/forums/minecraft/">Forums</a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="https://omgboards.com/threads/how-to-get-started.260944/">Minecraft</a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="http://discord.1moreblock.com/">Discord</a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="https://omgboards.com/forums/1mbplayers/post-thread">Support</a>
        </li>
      </ul>
    </div>
  </nav>

  <div class="container">

    <header>
      <!-- header section -->
      <h1>Player Groups - 1MoreBlock.com</h1>
      <div>We have a four-tier group hierarchy: free survival, free builders, patron, and special.</div>
      <hr>
    </header>