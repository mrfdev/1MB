<?php define('INCLUDED', true); ?>
<?php include 'includes/header.php'; ?>
<main>
  <!-- main content section -->
<div id="selectionTable" class="table-container">
  <div class="table">
    <div class="table-header">
      <div class="table-cell">
        <label class="groupLabel" for="groupSelect1">Free Survival</label>
      </div>
      <div class="table-cell">
        <label class="groupLabel" for="groupSelect2">Free Builders</label>
      </div>
      <div class="table-cell">
        <label class="groupLabel" for="groupSelect3">Patrons</label>
      </div>
      <div class="table-cell">
        <label class="groupLabel" for="groupSelect4">Special</label>
      </div>
    </div>
    <div class="table-row">
      <div class="table-cell">
        <select class="groupSelect" id="groupSelect1">
          <option value="" disabled selected>Select a Player Group</option>
<?php
  // Loop through $groupValues1 to build all options for the dropdown
  foreach ($groupValues1 as $key => $value) {
    echo "        
          <option value='$key'>$value</option>\n";
  }
?>
        </select>
      </div>
      <div class="table-cell">
        <select class="groupSelect" id="groupSelect2">
          <option value="" disabled selected>Select a Builder Group</option>
<?php
  // Loop through $groupValues2 to build all options for the dropdown
  foreach ($groupValues2 as $key => $value) {
    echo "        
          <option value='$key'>$value</option>\n";
  }
?>
        </select>
      </div>
      <div class="table-cell">
        <select class="groupSelect" id="groupSelect3">
          <option value="" disabled selected>Select a Patron Group</option>
<?php
  // Loop through $groupValues3 to build all options for the dropdown
  foreach ($groupValues3 as $key => $value) {
    echo "        
          <option value='$key'>$value</option>\n";
  }
?>
        </select>
      </div>
      <div class="table-cell">
        <select class="groupSelect" id="groupSelect4">
          <option value="" disabled selected>Select a Special Group</option>
<?php
  // Loop through $groupValues4 to build all options for the dropdown
  foreach ($groupValues4 as $key => $value) {
    echo "        
          <option value='$key'>$value</option>\n";
  }
?>
        </select>
      </div>
    </div>
  </div>
</div>

  <p>
  <h3 id="selectedGroup">You can type <strong>/groups</strong> in-game to find out what your current group is. </h3>
  </p>
  <div id="featuresTable" class="table-container">
    <!-- AJAX content will be loaded here -->
    <div class="table">
      <div class="table-header">
        <div class="table-cell">Feature</div>
        <div class="table-cell">Value</div>
      </div>
      <div class="table-row">
        <div class="table-cell">Players can join the server and type: /rules and /spawn at any time, as well as /wild, and /sethome. <br>
          <br>Features include: mcMMO RPG, rewards for Achievements, a /market, Multiple worlds and game types, you can sit on a chair, participate in fun events, have Jobs, there is an Economy, and more.
        </div>
        <div class="table-cell">Connect today, and join our never resetting Minecraft 1.20.x survival server, where we explore, mine, build, and survive together. <br>
          <br>We are a family-friendly community, and open to all over the age of 13. Bring friends and make new ones!
        </div>
      </div>
    </div>
  </div>
  <p>
    <small>Note: We refer to roles, ranks, groups all as one thing: groups.</small>
  </p>
</main> 

<?php include 'includes/footer.php'; ?>