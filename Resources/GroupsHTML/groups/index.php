<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Player Groups - 1MoreBlock.com</title>
  <!-- resources section -->
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <div class="container">

    <header>
      <!-- header section -->
      <h1>Player Groups - 1MoreBlock.com</h1>
    </header>

    <main>
    <!-- main content section -->

      <label for="groupSelect">Select a Player Group:</label>
      <select id="groupSelect">
        <option value="" disabled selected>Select a Player Group</option>
        <option value="group1">Group 1</option>
        <option value="group2">Group 2</option>
        <!-- Add options for all 20 player groups -->
      </select>

      <div id="featuresTable" class="table-container">
        <!-- AJAX content will be loaded here -->
          <div class="table">
            <div class="table-header">
              <div class="table-cell">Feature</div>
              <div class="table-cell">Value</div>
            </div>
          <div class="table-row">
            <div class="table-cell">Players can join the server and type: /rules and /spawn at any time, as well as /wild, and /sethome.<br><br>Features include: mcMMO RPG, rewards for Achievements, a /market, Multiple worlds and game types, you can sit on a chair, participate in fun events, have Jobs, there is an Economy, and more.</div>
            <div class="table-cell">Connect today, and join our never resetting Minecraft 1.20.x survival server, where we explore, mine, build, and survive together. <br><br>We are a family-friendly community, and open to all over the age of 13. Bring friends and make new ones!</div>
            </div>
          </div>
      </div>

    </main>

    <footer>
      <!-- footer section -->
      <p>Player Groups &copy; <?php echo date("Y"); ?> 1MoreBlock.com - Floris Fiedeldij Dop</p>
    </footer>

  </div>

  <!-- scripts section -->
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
  <script>
    $(document).ready(function() {
      $('#groupSelect').change(function() {
        var selectedGroup = $(this).val();
        $.ajax({
          url: 'get_features.php', // Replace with your backend endpoint
          type: 'POST',
          data: { group: selectedGroup },
          success: function(response) {
            $('#featuresTable').html(response);
          },
          error: function(xhr, status, error) {
            console.error(error);
          }
        });
      });
    });
  </script>
</body>
</html>
