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
    ),
    "group3" => array(
        "Feature 1" => "Value 7",
        "Feature 2" => "Value 8",
    ),
    "group4" => array(
        "Feature 1" => "Value 10",
        "Feature 2" => "Value 11",
    ),
    "group5" => array(
        "Feature 1" => "Value 13",
        "Feature 2" => "Value 14",
    ),
    "group6" => array(
        "Feature 1" => "Value 16",
        "Feature 2" => "Value 17",
    ),
    "group7" => array(
        "Feature 1" => "Value 19",
        "Feature 2" => "Value 20",
    ),
    "group8" => array(
        "Feature 1" => "Value 22",
        "Feature 2" => "Value 23",
    ),
    "group9" => array(
        "Feature 1" => "Value 25",
        "Feature 2" => "Value 26",
    ),
    "group10" => array(
        "Feature 1" => "Value 28",
        "Feature 2" => "Value 29",
    ),
    "group11" => array(
        "Feature 1" => "Value 31",
        "Feature 2" => "Value 32",
    ),
    "group12" => array(
        "Feature 1" => "Value 34",
        "Feature 2" => "Value 35",
    ),
    "group13" => array(
        "Feature 1" => "Value 37",
        "Feature 2" => "Value 38",
    ),
    "group14" => array(
        "Feature 1" => "Value 40",
        "Feature 2" => "Value 41",
    ),
    "group15" => array(
        "Feature 1" => "Value 43",
        "Feature 2" => "Value 44",
    ),
    "group16" => array(
        "Feature 1" => "Value 46",
        "Feature 2" => "Value 47",
    ),
    "group17" => array(
        "Feature 1" => "Value 49",
        "Feature 2" => "Value 50",
    ),
    "group18" => array(
        "Feature 1" => "Value 52",
        "Feature 2" => "Value 53",
    ),
    "group19" => array(
        "Feature 1" => "Value 55",
        "Feature 2" => "Value 56",
    ),
    "group20" => array(
        "Feature 1" => "Value 58",
        "Feature 2" => "Value 59",
    ),
    "group21" => array(
        "Feature 1" => "Value 61",
        "Feature 2" => "Value 62",
    ),
    "group22" => array(
        "Feature 1" => "Value 64",
        "Feature 2" => "Value 65",
    ),
    "group23" => array(
        "Feature 1" => "Value 67",
        "Feature 2" => "Value 68",
    ),
    "group24" => array(
        "Feature 1" => "Value 70",
        "Feature 2" => "Value 71",
    ),
    "group25" => array(
        "Feature 1" => "Value 73",
        "Feature 2" => "Value 74",
    )
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
