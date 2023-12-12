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
        <option value="group3">Group 3</option>
        <option value="group4">Group 4</option>
        <option value="group5">Group 5</option>
        <option value="group6">Group 6</option>
        <option value="group7">Group 7</option>
        <option value="group8">Group 8</option>
        <option value="group9">Group 9</option>
        <option value="group10">Group 10</option>
        <option value="group11">Group 11</option>
        <option value="group12">Group 12</option>
        <option value="group13">Group 13</option>
        <option value="group14">Group 14</option>
        <option value="group15">Group 15</option>
        <option value="group16">Group 16</option>
        <option value="group17">Group 17</option>
        <option value="group18">Group 18</option>
        <option value="group19">Group 19</option>
        <option value="group20">Group 20</option>
        <option value="group21">Group 21</option>
        <option value="group22">Group 22</option>
        <option value="group23">Group 23</option>
        <option value="group24">Group 24</option>
        <option value="group25">Group 25</option>
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
