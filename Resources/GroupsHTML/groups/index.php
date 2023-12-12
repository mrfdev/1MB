<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="description" content="1moreblock.com Groups for Minecraft server">
  <meta name="author" content="1moreblock.com - Floris Fiedeldij Dop">
  <title>Player Groups - 1MoreBlock.com</title>
  <!-- resources section -->
  <link rel="stylesheet" href="styles.css">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
</head>
<body>
  <!-- key/value for groups -->
  <?php include 'groups.php'; ?>

  <!-- Navigation -->
  <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
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

    <main>
    <!-- main content section -->

      <label for="groupSelect">Select a Player Group:</label>
      <select id="groupSelect">
        <option value="" disabled selected>Select a Player Group</option>
<?php
  // Loop through $groupValues to build all options for the dropdown
  foreach ($groupValues as $key => $value) {
    echo "        <option value='$key'>$value</option>\n";
  }
?>
      </select>

      <p><h2 id="selectedGroup">You can type /groups in-game to find out which group you are in.</h2></p>

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

  </div>

  <footer class="py-3 bg-dark">
  <!-- footer section -->
    <p class="m-0 text-center text-white">Player Groups &copy; 1977-<?php echo date("Y"); ?> 1MoreBlock.com - Floris Fiedeldij Dop
    <br>
    <small>Note please that Floris, the team members, OMGboards.com nor 1MoreBlock.com, claim or pretend to be-, nor are associated with-, and are not supported by Mojang or Microsoft, Discord, or any other brandname. Server owner mrfloris (mrfloris@gmail.com)</small>
    </p>
  </footer>

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
  <script>
    const groupValues = {
      'group1': 'Newbie',
      'group2': 'Rookie',
      'group3': 'Beginner',
      'group4': 'Learner',
      'group5': 'Novice',
      'group6': 'Player',
      'group7': 'Member',
      'group8': 'Adept',
      'group9': 'Skilled',
      'group10': 'Champion',
      'group11': 'Expert',
      'group12': 'Elite',
      'group13': 'Builder',
      'group14': 'Rogue',
      'group15': 'Prodigy',
      'group16': 'Savant',
      'group17': 'VIP',
      'group18': 'Patron',
      'group19': 'MVP',
      'group20': 'EPIC',
      'group21': 'Veteran',
      'group22': 'Legendary',
      'group23': 'Helper',
      'group23': 'Mod',
      'group24': 'Admin',
      'group25': 'Unique',
      'group26': 'Owner'
    };

    const groupSelect = document.getElementById('groupSelect');
    const selectedGroup = document.getElementById('selectedGroup');

    groupSelect.addEventListener('change', function() {
      const selectedValue = this.value;
      selectedGroup.textContent = groupValues[selectedValue] || '';
    });
  </script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</body>
</html>
