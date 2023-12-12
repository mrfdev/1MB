<?php
// Player groups and their features (c) 1MoreBlock.com - Floris Fiedeldij Dop
// Surely in the future these values can be auto generated, I don't have the time to learn this right now. 
$playerGroups = array(
    "group1" => array(
        "Feature 1" => "Value 1",
        "Feature 2" => "Value 2",
    ),
    "group2" => array(
        "Feature 1" => "Value 4",
        "Feature 2" => "Value 5",
    )
    // 2024 groups are like 20, r&repeat
);

// Which group is sent via AJAX POST request
if (isset($_POST['group'])) {
    $selectedGroup = $_POST['group'];

    // Lets only deal with existing groups
    if (array_key_exists($selectedGroup, $playerGroups)) {
        // Retrieve features for the selected group
        $features = $playerGroups[$selectedGroup];

        // Dirty bit of HTML to visualize things

        // Gotta have a top row
        $html = '<div class="table">';
        $html .= '    <div class="table-header">';
        $html .= '    <div class="table-cell">Feature</div>';
        $html .= '    <div class="table-cell">Value</div>';
        $html .= '  </div>';

        // time to build it up
        foreach ($features as $feature => $value) {
            $html .= '    <div class="table-row">';
            $html .= '      <div class="table-cell">' . $feature . '</div>';
            $html .= '      <div class="table-cell">' . $value . '</div>';
            $html .= '    </div>';
        }

        // closing container
        $html .= '</div>';

        // the magical response
        echo $html;
    } else {
        // or a default oopsy response
        echo 'Invalid group';
    }
} else {
    // or instruct what to do
    echo 'Select a group from the dropdown.';
}
?>
