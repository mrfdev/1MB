<?php
if (!defined('INCLUDED')) {
  header('HTTP/1.0 403 Forbidden');
  exit('Direct access not allowed');
}
?>
  </div>

  <footer class="py-3 bg-dark">
  <!-- footer section -->
    <div class="container navbar-dark bg-dark headerFooterFix">
      <p class="m-0 text-center text-white">Player Groups &copy; 1977-<?php echo date("Y"); ?> 1MoreBlock.com - Floris Fiedeldij Dop
      <br>
      <small>Note please that Floris, the team members, OMGboards.com nor 1MoreBlock.com, claim or pretend to be-, nor are associated with-, <br>and are not supported by Mojang or Microsoft, Discord, or any other brandname. <br>Server owner mrfloris (<span id="serverowner"></span>)</small>
      </p>
    </div>
  </footer>

  <!-- scripts section -->
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
  <script>
    $(document).ready(function() {
      // Get all elements with class 'groupSelect' and attach change event
      $('.groupSelect').change(function() {
        var selectedGroup = $(this).val();
        $.ajax({
          url: 'includes/get_features.php', // Replace with your backend endpoint
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

      // Update selected group when any dropdown changes
      $('.groupSelect').change(function() {
        const selectedValue = $(this).val();
        const groupValues = <?php echo json_encode($groupValues1 + $groupValues2 + $groupValues3 + $groupValues4); ?>;
        const selectedGroup = document.getElementById('selectedGroup');
        selectedGroup.textContent = groupValues[selectedValue] || '';
      });
    });
  </script>
<script type="text/javascript">
  var firstPart = "&#109;&#114;&#102;&#108;&#111;&#114;&#105;&#115;";
  var atSymbol = "&#64;";
  var secondPart = "&#103;&#109;&#97;&#105;&#108;&#46;&#99;&#111;&#109;";
  var email = firstPart + atSymbol + secondPart;
  document.getElementById("serverowner").innerHTML = email;
</script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</body>
</html>
