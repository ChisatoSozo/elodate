use super::internal_prefs::{
    Category, Linear, LinearMapping, MeanAlteration, PreferenceConfig, StdDevAlteration, UIElement,
};

//TODO: on a database of 10000 only 9998 are returned with no preference
pub const P_NONE: f64 = 1.0;
pub const P_NONE_PROP: f64 = 0.05;

pub static PREFS_CONFIG: [PreferenceConfig; PREFS_CARDINALITY] = [
    PreferenceConfig {
        name: "age",
        group: "age",
        ui_element: UIElement::Slider,
        display: "Age",
        category: Category::Mandatory,
        value_question: "",
        range_question: "How old do you want your partner to be?",
        min: 18,
        max: 120,
        mean: 35.0,
        std_dev: 20.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: false,
        default: None,
        labels: None,
        probability_to_be_none: 0.0,
    },
    PreferenceConfig {
        name: "percent_male",
        group: "gender",
        ui_element: UIElement::GenderPicker,
        display: "Gender",
        category: Category::Mandatory,
        value_question: "What's your gender?",
        range_question: "What gender are you interested in?",
        min: 0,
        max: 100,
        mean: 50.0,
        std_dev: 1000.0,
        mean_alteration: MeanAlteration::FromValue(Linear {
            slope: -1.0,
            intercept: 100.0,
        }),
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: false,
        default: Some(100),
        labels: None,
        probability_to_be_none: 0.0,
    },
    PreferenceConfig {
        name: "percent_female",
        group: "gender",
        ui_element: UIElement::GenderPicker,
        display: "Gender",
        category: Category::Mandatory,
        value_question: "What's your gender?",
        range_question: "What gender are you interested in?",
        min: 0,
        max: 100,
        mean: 50.0,
        std_dev: 100000.0,
        mean_alteration: MeanAlteration::FromValue(Linear {
            slope: -1.0,
            intercept: 100.0,
        }),
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: false,
        default: Some(0),
        labels: None,
        probability_to_be_none: 0.0,
    },
    PreferenceConfig {
        name: "latitude",
        group: "location",
        ui_element: UIElement::LocationPicker,
        display: "Location",
        category: Category::Mandatory,
        value_question: "Where are ya?",
        range_question: "How far away are you willing to go to meet someone?",
        min: -32767,
        max: 32767,
        mean: 0.0,
        std_dev: 1000000.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: Some(LinearMapping {
            real_min: -90.0,
            real_max: 90.0,
        }),
        optional: false,
        default: None,
        labels: None,
        probability_to_be_none: 0.0,
    },
    PreferenceConfig {
        name: "longitude",
        group: "location",
        ui_element: UIElement::LocationPicker,
        display: "Location",
        category: Category::Mandatory,
        value_question: "Where are ya?",
        range_question: "How far away are you willing to go to meet someone?",
        min: -32767,
        max: 32767,
        mean: 0.0,
        std_dev: 0.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: Some(LinearMapping {
            real_min: -180.0,
            real_max: 180.0,
        }),
        optional: false,
        default: None,
        labels: None,
        probability_to_be_none: 0.0,
    },
    PreferenceConfig {
        name: "salary_per_year",
        group: "salary_per_year",
        ui_element: UIElement::Slider,
        display: "Salary",
        category: Category::Financial,
        value_question: "How much do you make per year?",
        range_question: "How much do you want your partner to make?",
        min: 0,
        max: 100,
        mean: 50000.0,
        std_dev: 25000.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.3,
            intercept: 0.0,
        }),
        linear_mapping: Some(LinearMapping {
            real_min: 0.0,
            real_max: 1000000.0,
        }),
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "height_cm",
        group: "height_cm",
        ui_element: UIElement::Slider,
        display: "Height (cm)",
        category: Category::Physical,
        value_question: "How tall are you?",
        range_question: "How tall do you want your partner to be?",
        min: 0,
        max: 250,
        mean: 175.0,
        std_dev: 10.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "bmi",
        group: "bmi",
        ui_element: UIElement::Slider,
        display: "BMI",
        category: Category::Physical,
        value_question: "What's your BMI?",
        range_question: "What BMI do you want your partner to have?",
        min: 0,
        max: 100,
        mean: 25.0,
        std_dev: 5.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "number_of_times_a_week_you_want_to_have_sex",
        group: "number_of_times_a_week_you_want_to_have_sex",
        ui_element: UIElement::Slider,
        display: "Number of Times a Week You Want to Have Sex",
        category: Category::Sexual,
        value_question: "How many times a week do you want to have Sex?",
        range_question: "How many times a week do you want your partner to want to have Sex?",
        min: 0,
        max: 100,
        mean: 2.0,
        std_dev: 2.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "is_trans",
        group: "is_trans",
        ui_element: UIElement::Slider,
        display: "Is Transgender",
        category: Category::Lgbt,
        value_question: "Are you trans?",
        range_question: "Do you want your partner to be trans?",
        min: 0,
        max: 1,
        mean: 0.0,
        std_dev: 0.4,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "is_queer",
        group: "is_queer",
        ui_element: UIElement::Slider,
        display: "Is Queer",
        category: Category::Lgbt,
        value_question: "Are you queer?",
        range_question: "Do you want your partner to be queer?",
        min: 0,
        max: 1,
        mean: 0.0,
        std_dev: 0.4,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "political_affiliation",
        group: "political_affiliation",
        ui_element: UIElement::Slider,
        display: "Political Affiliation",
        category: Category::Beliefs,
        value_question: "What's your political affiliation?",
        range_question: "What political affiliation do you want your partner to have?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some([
            "Leftist",
            "Liberal",
            "Centrist",
            "Conservative",
            "Traditionalist",
        ]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "fitness_level",
        group: "fitness_level",
        ui_element: UIElement::Slider,
        display: "Fitness Level",
        category: Category::Physical,
        value_question: "What's your fitness level?",
        range_question: "What fitness level do you want your partner to have?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some(["Couch potato", "Sedentary", "Average", "Fit", "Athlete"]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "number_of_children",
        group: "number_of_children",
        ui_element: UIElement::Slider,
        display: "Number of Children You Have",
        category: Category::Lifestyle,
        value_question: "How many children do you have?",
        range_question: "How many children do you want your partner to have?",
        min: 0,
        max: 10,
        mean: 1.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "number_of_dogs",
        group: "number_of_dogs",
        ui_element: UIElement::Slider,
        display: "Number of Dogs You Have",
        category: Category::Lifestyle,
        value_question: "How many dogs do you have?",
        range_question: "How many dogs do you want your partner to have?",
        min: 0,
        max: 10,
        mean: 0.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "number_of_cats",
        group: "number_of_cats",
        ui_element: UIElement::Slider,
        display: "Number of Cats You Have",
        category: Category::Lifestyle,
        value_question: "How many cats do you have?",
        range_question: "How many cats do you want your partner to have?",
        min: 0,
        max: 10,
        mean: 0.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "vegetarianness",
        group: "vegetarianness",
        ui_element: UIElement::Slider,
        display: "Vegetarianness",
        category: Category::Diet,
        value_question: "How vegetarian are you?",
        range_question: "How vegetarian do you want your partner to be?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some([
            "Carnivore",
            "Omnivore",
            "Pescatarian",
            "Vegetarian",
            "Vegan",
        ]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "gamerness_level",
        group: "gamerness_level",
        ui_element: UIElement::Slider,
        display: "Gamerness Level",
        category: Category::Hobbies,
        value_question: "How much of a gamer are you?",
        range_question: "How much of a gamer do you want your partner to be?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some([
            "I don't play games",
            "Casual",
            "Average",
            "Hardcore",
            "Professional",
        ]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "extroversion_level",
        group: "extroversion_level",
        ui_element: UIElement::Slider,
        display: "Extroversion Level",
        category: Category::Lifestyle,
        value_question: "How extroverted are you?",
        range_question: "How extroverted do you want your partner to be?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some([
            "Introvert",
            "Ambivert",
            "Average",
            "Extrovert",
            "Life of the party",
        ]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "how_much_you_want_to_go_outside",
        group: "how_much_you_want_to_go_outside",
        ui_element: UIElement::Slider,
        display: "How Much You Want to Go Outside",
        category: Category::Hobbies,
        value_question: "How much do you want to go outside?",
        range_question: "How much do you want your partner to want to go outside?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some([
            "Agoraphobic",
            "Homebody",
            "Average",
            "Outdoorsy",
            "Wanderlust",
        ]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "how_much_you_want_to_travel",
        group: "how_much_you_want_to_travel",
        ui_element: UIElement::Slider,
        display: "How Much You Want to Travel",
        category: Category::Hobbies,
        value_question: "How much do you want to travel?",
        range_question: "How much do you want your partner to want to travel?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some([
            "I don't want to travel",
            "Homebody",
            "Average",
            "Traveler",
            "Wanderlust",
        ]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "how_cleanly_are_you",
        group: "how_cleanly_are_you",
        ui_element: UIElement::Slider,
        display: "How Cleanly Are You",
        category: Category::Lifestyle,
        value_question: "How cleanly are you?",
        range_question: "How cleanly do you want your partner to be?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some([
            "Slob",
            "Average",
            "Clean",
            "Neat freak",
            "Obsessive-compulsive",
        ]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "hoarder_level",
        group: "hoarder_level",
        ui_element: UIElement::Slider,
        display: "Hoarder Level",
        category: Category::Lifestyle,
        value_question: "How much of a hoarder are you?",
        range_question: "How much of a hoarder do you want your partner to be?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some(["Monk", "Minimalist", "Average", "Collector", "Hoarder"]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "how_much_you_want_to_have_children",
        group: "how_much_you_want_to_have_children",
        ui_element: UIElement::Slider,
        display: "How Much You Want to Have Children",
        category: Category::Future,
        value_question: "How much do you want to have children?",
        range_question: "How much do you want your partner to want to have children?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some([
            "I don't want children",
            "I don't want children now",
            "I might want children",
            "I want children",
            "I want many children",
        ]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "how_much_you_want_to_get_married",
        group: "how_much_you_want_to_get_married",
        ui_element: UIElement::Slider,
        display: "How Much You Want to Get Married",
        category: Category::Future,
        value_question: "How much do you want to get married?",
        range_question: "How much do you want your partner to want to get married?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some([
            "I don't want to get married",
            "I don't want to get married now",
            "I might want to get married",
            "I want to get married",
            "I want to get married soon",
        ]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "drinks_consumed_per_week",
        group: "drinks_consumed_per_week",
        ui_element: UIElement::Slider,
        display: "Drinks Consumed per Week",
        category: Category::Substances,
        value_question: "How many drinks do you have a week?",
        range_question: "How many drinks do you want your partner to have a week?",
        min: 0,
        max: 50,
        mean: 5.0,
        std_dev: 5.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "smokes_per_day",
        group: "smokes_per_day",
        ui_element: UIElement::Slider,
        display: "Smokes per Day",
        category: Category::Substances,
        value_question: "How many cigarettes do you smoke a day?",
        range_question: "How many cigarettes do you want your partner to smoke a day?",
        min: 0,
        max: 50,
        mean: 2.0,
        std_dev: 5.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "marajuana_consumed_per_week_joints",
        group: "marajuana_consumed_per_week_joints",
        ui_element: UIElement::Slider,
        display: "Marijuana Consumed per Week (Joints)",
        category: Category::Substances,
        value_question: "How much weed do you smoke a week, if you were to measure it in joints?",
        range_question: "How much weed do you want your partner to smoke a week, if they were to measure it in joints?",
        min: 0,
        max: 50,
        mean: 2.0,
        std_dev: 2.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "hours_a_day_spent_on_social_media",
        group: "hours_a_day_spent_on_social_media",
        ui_element: UIElement::Slider,
        display: "Hours a Day Spent on Social Media",
        category: Category::Hobbies,
        value_question: "How many hours a day do you spend on social media?",
        range_question: "How many hours a day do you want your partner to spend on social media?",
        min: 0,
        max: 24,
        mean: 2.0,
        std_dev: 2.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "pubic_hair_length",
        group: "pubic_hair_length",
        ui_element: UIElement::Slider,
        display: "Pubic Hair Length",
        category: Category::Sexual,
        value_question: "How long is your pubic hair?",
        range_question: "How long do you want your partner's pubic hair to be?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some(["Shaved", "Trimmed", "Average", "Bushy", "Jungle"]),
        probability_to_be_none: P_NONE,
    },

    PreferenceConfig {
        name: "number_of_sexual_partners",
        group: "number_of_sexual_partners",
        ui_element: UIElement::Slider,
        display: "Number of Sexual Partners",
        category: Category::Sexual,
        value_question: "How many sexual partners have you had?",
        range_question: "How many sexual partners do you want your partner to have had?",
        min: 0,
        max: 100,
        mean: 5.0,
        std_dev: 5.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },

    PreferenceConfig {
        name: "debt",
        group: "debt",
        ui_element: UIElement::Slider,
        display: "Debt",
        category: Category::Financial,
        value_question: "How much debt do you have?",
        range_question: "How much debt do you want your partner to have?",
        min: 0,
        max: 100,
        mean: 5000.0,
        std_dev: 5000.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.3,
            intercept: 0.0,
        }),
        linear_mapping: Some(LinearMapping {
            real_min: 0.0,
            real_max: 1000000.0,
        }),
        optional: true,
        default: None,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "level_of_kink",
        group: "level_of_kink",
        ui_element: UIElement::Slider,
        display: "Level of Kink",
        category: Category::Sexual,
        value_question: "How kinky are you?",
        range_question: "How kinky do you want your partner to be?",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        default: None,
        labels: Some([
            "Vanilla",
            "Open-minded",
            "Adventurous",
            "Kinky",
            "Fetishist",
        ]),
        probability_to_be_none: P_NONE,
    },
];

pub const PREFS_CARDINALITY: usize = 33;