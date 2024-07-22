use super::internal_prefs::{
    default_preference_config, Category, Linear, LinearMapping, MeanAlteration, PreferenceConfig, StdDevAlteration, UIElement
};

pub const P_NONE: f64 = 1.0;
pub const P_NONE_PROP: f64 = 0.05;

pub static PREFS_CONFIG: [PreferenceConfig; PREFS_CARDINALITY] = [
    // Mandatory Category
    PreferenceConfig {
        name: "age",
        group: "age",
        display: "Age",
        ui_element: UIElement::NumberInput,
        category: Category::Mandatory,
        value_question: "",
        range_question: "How old do you want your partner to be?",
        min: 18,
        max: 120,
        mean: 35.0,
        std_dev: 20.0,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        non_optional_message: Some("Set your age"),
        probability_to_be_none: 0.0,
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "percent_male",
        group: "gender",
        ui_element: UIElement::GenderPicker,
        display: "Gender",
        category: Category::Mandatory,
        value_question: "What's your gender?",
        range_question: "What gender are you interested in?",
        max: 100,
        mean: 50.0,
        std_dev: 1000.0,
        mean_alteration: MeanAlteration::FromValue(Linear {
            slope: -1.0,
            intercept: 100.0,
        }),
        non_optional_message: Some("Pick a gender"),
        default: Some(100),
        probability_to_be_none: 0.0,
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "percent_female",
        group: "gender",
        ui_element: UIElement::GenderPicker,
        display: "Gender",
        category: Category::Mandatory,
        value_question: "What's your gender?",
        range_question: "What gender are you interested in?",
        max: 100,
        mean: 50.0,
        std_dev: 100000.0,
        mean_alteration: MeanAlteration::FromValue(Linear {
            slope: -1.0,
            intercept: 100.0,
        }),
        non_optional_message: Some("Pick a gender"),
        default: Some(0),
        probability_to_be_none: 0.0,
        ..default_preference_config()
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
        linear_mapping: Some(LinearMapping {
            real_min: -90.0,
            real_max: 90.0,
        }),
        non_optional_message: Some("Click 'Get Location'"),
        probability_to_be_none: 0.0,
        ..default_preference_config()
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
        linear_mapping: Some(LinearMapping {
            real_min: -180.0,
            real_max: 180.0,
        }),
        non_optional_message: Some("Click 'Get Location'"),
        probability_to_be_none: 0.0,
        ..default_preference_config()
    },

    // Physical Category
    PreferenceConfig {
        name: "height_cm",
        group: "height_and_weight",
        ui_element: UIElement::HeightAndWeight,
        display: "Height and Weight",
        category: Category::Physical,
        value_question: "What shape are you?",
        range_question: "What shape do you want your partner to be?",
        max: 250,
        mean: 175.0,
        std_dev: 10.0,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "bmi",
        group: "height_and_weight",
        ui_element: UIElement::HeightAndWeight,
        display: "Height and Weight",
        category: Category::Physical,
        value_question: "What shape are you?",
        range_question: "What shape do you want your partner to be?",
        max: 50,
        mean: 25.0,
        std_dev: 5.0,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "fitness_level",
        group: "fitness_level",
        display: "Fitness Level",
        category: Category::Physical,
        value_question: "What's your fitness level?",
        range_question: "What fitness level do you want your partner to have?",
        labels: Some(&["Couch potato", "Sedentary", "Average", "Fit", "Athlete"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "body_hair",
        display: "Body Hair",
        category: Category::Physical,
        value_question: "How hairy are you (body-hair/leg-hair/armpit-hair)?",
        range_question: "How hairy do you want your partner to be?",
        labels: Some(&["Smooth", "Trimmed", "Average", "Hairy", "Help I'm lost in the forest and haven't seen the sun in years"]),
        ..default_preference_config()
    },

    // Financial Category
    PreferenceConfig {
        name: "salary_per_year",
        group: "salary_per_year",
        display: "Salary",
        category: Category::Financial,
        value_question: "How much do you make per year?",
        range_question: "How much do you want your partner to make?",
        max: 18,
        mean: 4.0,
        std_dev: 4.0,
        labels: Some(&[
            "Unemployed",
            "Unemployed (Student or Government Aid)",
            "$10,000",
            "$20,000",
            "$30,000",
            "$40,000",
            "$50,000",
            "$60,000",
            "$70,000",
            "$80,000",
            "$90,000",
            "$100,000",
            "$120,000",
            "$150,000",
            "$200,000",
            "$250,000",
            "$350,000",
            "$500,000",
            "$1,000,000+",
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "debt",
        group: "debt",
        display: "Debt",
        category: Category::Financial,
        value_question: "How much debt do you have?",
        range_question: "How much debt do you want your partner to have?",
        max: 17,
        mean: 4.0,
        std_dev: 4.0,
        labels: Some(&[
            "$0",
            "$10,000",
            "$20,000",
            "$30,000",
            "$40,000",
            "$50,000",
            "$60,000",
            "$70,000",
            "$80,000",
            "$90,000",
            "$100,000",
            "$120,000",
            "$150,000",
            "$200,000",
            "$250,000",
            "$350,000",
            "$500,000",
            "$1,000,000+",
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "financial_planning_importance",
        group: "financial_planning_importance",
        display: "Importance of Financial Planning",
        category: Category::Financial,
        value_question: "How important is financial planning to you?",
        range_question: "How important should financial planning be to your partner?",
        labels: Some(&["Not important", "Somewhat important", "Important", "Very important", "Obsessed with it"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "budgeting_style",
        group: "budgeting_style",
        display: "Budgeting Style",
        category: Category::Financial,
        value_question: "How do you approach budgeting?",
        range_question: "How do you want your partner to approach budgeting?",
        labels: Some(&["I don't budget", "I budget occasionally", "I budget regularly", "I budget meticulously", "I have a spreadsheet for every penny"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "financial_transparency_in_relationships",
        group: "financial_transparency_in_relationships",
        display: "Financial Transparency in Relationships",
        category: Category::Financial,
        max: 3,
        value_question: "How transparent are you about your finances in a relationship?",
        range_question: "How transparent do you want your partner to be about their finances in a relationship?",
        labels: Some(&["I don't talk about money", "I talk about money when necessary", "I'm open about my finances", "So here's an invitation to the shared relationship budget spreadsheet, please upload all receipts"]),
        ..default_preference_config()
    },

    // Sexual Category
    PreferenceConfig {
        name: "number_of_times_a_week_you_want_to_have_sex",
        group: "number_of_times_a_week_you_want_to_have_sex",
        display: "Number of Times a Week You Want to Have Sex",
        category: Category::Sexual,
        value_question: "How many times a week do you want to have Sex?",
        range_question: "How many times a week do you want your partner to want to have Sex?",
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        labels: Some(&["Never", "1-2", "3-5", "6-10", "11-20", "21-50", "50+"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "level_of_kink",
        group: "level_of_kink",
        display: "Level of Kink",
        category: Category::Sexual,
        value_question: "How kinky are you?",
        range_question: "How kinky do you want your partner to be?",
        labels: Some(&[
            "Vanilla",
            "Open-minded",
            "Adventurous",
            "Kinky",
            "Fetishist",
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "pubic_hair_length",
        group: "pubic_hair_length",
        display: "Pubic Hair Length",
        category: Category::Sexual,
        value_question: "How long is your pubic hair?",
        range_question: "How long do you want your partner's pubic hair to be?",
        labels: Some(&["Shaved", "Trimmed", "Average", "Bushy", "Jungle"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "pornography_viewing",
        group: "pornography_viewing",
        display: "Porn",
        category: Category::Sexual,
        value_question: "How often do you view porn?",
        range_question: "How often do you want your partner to view porn?",
        labels: Some(&["Never", "Rarely", "Occasionally", "Frequently", "Daily"]),
        ..default_preference_config()
    },

    // LGBT Category
    PreferenceConfig {
        name: "lgbt_community_involvement",
        group: "lgbt_community_involvement",
        display: "LGBT Community Involvement",
        category: Category::Lgbt,
        value_question: "How involved are you in the LGBT community?",
        range_question: "How involved do you want your partner to be in the LGBT community?",
        labels: Some(&["Not at all", "Somewhat", "Moderately", "Very", "Extremely"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "is_trans",
        group: "is_trans",
        display: "Is Transgender",
        category: Category::Lgbt,
        value_question: "Are you trans?",
        range_question: "Do you want your partner to be trans?",
        max: 1,
        mean: 0.0,
        std_dev: 0.4,
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "is_queer",
        group: "is_queer",
        display: "Is Queer",
        category: Category::Lgbt,
        value_question: "Are you queer?",
        range_question: "Do you want your partner to be queer?",
        max: 1,
        mean: 0.0,
        std_dev: 0.4,
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "gender_non_conforming_comfort",
        group: "gender_non_conforming_comfort",
        display: "Comfort with gender non conforming people",
        category: Category::Lgbt,
        value_question: "How comfortable are you with gender non conforming people?",
        range_question: "How comfortable do you want your partner to be with gender non conforming people?",
        labels: Some(&["There are only two genders, and I'm not too sure about the second one", "I'm not too fond of gender non-conforming folk", "I'm open to the idea/don't care", "I actively encourage and seek out gender non-conforming people", "I do not and will not interact with cis-normative 'people'"]),
        ..default_preference_config()
    },
    // End of LGBT Category

    // Background Category
    PreferenceConfig {
        name: "education_level",
        group: "education_level",
        display: "Education Level",
        category: Category::Background,
        value_question: "What is your level of education?",
        range_question: "What level of education do you prefer in a partner?",
        max: 5,
        labels: Some(&["Can not read and does *not* want to learn", "High School", "Trade certification", "Bachelor's", "Master's", "Doctorate"]),
        ..default_preference_config()
    },

    PreferenceConfig {
        name: "number_of_sexual_partners",
        group: "number_of_sexual_partners",
        display: "Number of Sexual Partners",
        category: Category::Background,  // Changed from Sexual to Background
        value_question: "How many sexual partners have you had?",
        range_question: "How many sexual partners do you want your partner to have had?",
        max: 7,
        mean: 2.0,
        std_dev: 1.0,
        labels: Some(&[
            "Virgin",
            "1-2",
            "3-5",
            "6-10",
            "11-20",
            "21-50",
            "51-100",
            "100+",
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "years_of_work_experience",
        group: "years_of_work_experience",
        display: "Years of Work Experience",
        category: Category::Background,
        value_question: "How many years of work experience do you have?",
        range_question: "How many years of work experience do you prefer in a partner?",
        max: 50,
        mean: 10.0,
        std_dev: 5.0,
        ..default_preference_config()
    },
    // End of Background Category
    // Relationship Style Category
    PreferenceConfig {
        name: "communication_style",
        group: "communication_style",
        display: "Communication Style",
        category: Category::RelationshipStyle,
        value_question: "How direct is your communication style?",
        range_question: "How direct would you like your partner's communication style to be?",    
        labels: Some(&["There will be a great hunt filled with perils, misdirection, and traps to find out what I'm thinking", "Indirect", "Balanced", "Direct", "There is no separation between my thoughts and my words"]),
        ..default_preference_config()
    },
    
    PreferenceConfig {
        name: "romance_level",
        group: "romance_level",
        display: "Romance",
        category: Category::RelationshipStyle,
        value_question: "How romantic are you in a relationship?",
        range_question: "How romantic do you want your partner to be?",    
        labels: Some(&["If you look longingly into my eyes, I *will* hurt you", "I'm not a fan of romance", "Occasionally romantic", "Romantic", "I'm a hopeless romantic and I will write you love letters every day"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "pda",
        group: "pda",
        display: "Public Displays of Affection",
        category: Category::RelationshipStyle,
        value_question: "How do you feel about public displays of affection?",
        range_question: "How do you want your partner to feel about public displays of affection?",
        labels: Some(&["I will never touch you in public", "I will hold your hand in public", "I will kiss you in public", "I will make out with you in public", "I will be constantly crawling all over you in public"]),
        ..default_preference_config()
    },
    
    PreferenceConfig {
        name: "conflict_resolution_style",
        group: "conflict_resolution_style",
        display: "Conflict Resolution Style",
        category: Category::RelationshipStyle,
        value_question: "How do you typically approach resolving conflicts in a relationship?",
        range_question: "What conflict resolution style would you prefer in a partner?",
        labels: Some(&[
            "Avoidant (Tend to withdraw or postpone addressing issues)",
            "Accommodating (Often give in to maintain harmony)",
            "Compromising (Seek middle ground, willing to give and take)",
            "Collaborative (Work together to find mutually satisfying solutions)",
            "Assertive (Directly address issues, stand firm on needs)"
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "polyamory_level",
        group: "polyamory_level",
        display: "Polyamory Level",
        category: Category::RelationshipStyle,
        value_question: "How open are you to polyamory?",
        range_question: "How open would you like your partner to be to polyamory?",    
        labels: Some(&["Monogamy Mandatory", "Monogamy Preferred", "Open to Polyamory", "Polyamory Preferred", "Polyamory Mandatory"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "jealousy_level",
        group: "jealousy_level",
        display: "Jealousy",
        category: Category::RelationshipStyle,
        value_question: "How jealous are you in a relationship?",
        range_question: "How jealous do you want your partner to be?",
        labels: Some(&["Not at all", "Slightly", "Moderately", "Very", "Extremely"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "independence_level",
        group: "independence_level",
        display: "Desired Personal Space in Relationship",
        category: Category::RelationshipStyle,
        value_question: "How much personal space and autonomy do you need in a relationship?",
        range_question: "How much personal space and autonomy do you want your partner to need?",
        labels: Some(&[
            "Prefers Constant Togetherness",
            "Enjoys Frequent Interaction",
            "Balanced Need for Togetherness and Alone Time",
            "Values Significant Personal Space",
            "Highly Values Autonomy and Independence"
        ]),
        ..default_preference_config()
    },
    
    PreferenceConfig {
        name: "emotional_openness",
        group: "emotional_openness",
        display: "Emotional Openness",
        category: Category::RelationshipStyle,
        value_question: "How emotionally open are you?",
        range_question: "How emotionally open do you want your partner to be?",    
        labels: Some(&["Very Reserved", "Somewhat Reserved", "Balanced", "Somewhat Open", "Very Open"]),
        ..default_preference_config()
    },
    
    PreferenceConfig {
        name: "decision_making_style",
        group: "decision_making_style",
        display: "Decision Making Style",
        category: Category::RelationshipStyle,
        value_question: "How do you prefer to make decisions in a relationship?",
        range_question: "How would you like your partner to make decisions?",    
        labels: Some(&["Very Impulsive", "Somewhat Impulsive", "Balanced", "Somewhat Deliberate", "Very Deliberate"]),
        ..default_preference_config()
    },
    
    PreferenceConfig {
        name: "social_interaction_as_couple",
        group: "social_interaction_as_couple",
        display: "Social Interaction as a Couple",
        category: Category::RelationshipStyle,
        value_question: "How much do you prefer to socialize as a couple?",
        range_question: "How much would you like your partner to want to socialize as a couple?",    
        labels: Some(&["Prefer Separate Social Lives", "Occasional Joint Activities", "Balanced", "Frequent Joint Activities", "Always Together"]),
        ..default_preference_config()
    },
    //End of Relationship Style Category

    // Beliefs Category
    PreferenceConfig {
        name: "political_affiliation",
        group: "political_affiliation",
        display: "Political Affiliation",
        category: Category::Beliefs,
        value_question: "What's your political affiliation?",
        range_question: "What political affiliation do you want your partner to have?",
        labels: Some(&[
            "Leftist",
            "Liberal",
            "Centrist",
            "Conservative",
            "Traditionalist",
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "environmentalism_level",
        group: "environmentalism_level",
        display: "Environmentalism",
        category: Category::Beliefs,
        value_question: "How environmentally conscious are you?",
        range_question: "How environmentally conscious do you want your partner to be?",
        labels: Some(&["I do not believe in 'climate change'", "I believe in climate change but it ain't gonna stop me from rollin' coal", "Don't particularly care one way or the other", "I recycle and do what I can when convenient", "I am literally Greta Thunberg"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "spirituality_level",
        group: "spirituality_level",
        display: "Importance of Spirituality in Life",
        category: Category::Beliefs,
        value_question: "How significant is spirituality or faith in your life and daily practices?",
        range_question: "How important is it that your partner values spirituality or faith?",
        labels: Some(&[
            "Not spiritual at all",
            "Open to spiritual ideas",
            "Moderately spiritual",
            "Spirituality is important",
            "Spirituality is central to life"
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "religion_importance",
        group: "religion_importance",
        display: "Adherence to Organized Religion",
        category: Category::Beliefs,
        value_question: "How actively do you participate in organized religious activities or follow religious doctrines?",
        range_question: "How important is it that your partner participates in organized religion?",
        labels: Some(&[
            "Not religious at all",
            "Culturally religious",
            "Moderately religious",
            "Regularly practices religion",
            "Deeply committed to religious life"
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "conspiracy_belief",
        group: "conspiracy_belief",
        display: "Conspiracy Theory Belief",
        category: Category::Beliefs,
        value_question: "What's your stance on conspiracy theories?",
        range_question: "What stance on conspiracy theories do you want your partner to have?",
        labels: Some(&["Skeptic", "Occasional believer", "Open-minded", "Enthusiast", "True believer"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "mindfulness_frequency",
        group: "mindfulness_frequency",
        display: "Mindfulness Practice Frequency",
        category: Category::Beliefs,
        value_question: "How often do you practice mindfulness or meditation?",
        range_question: "How often do you want your partner to practice mindfulness or meditation?",
        labels: Some(&["Never", "Rarely", "Occasionally", "Frequently", "Daily"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "alternative_medicine_view",
        group: "alternative_medicine_view",
        display: "View on Alternative Medicine",
        category: Category::Beliefs,
        value_question: "What's your view on alternative medicine?",
        range_question: "What view on alternative medicine do you want your partner to have?",
        labels: Some(&["Strictly scientific", "Skeptical but open", "Balanced approach", "Prefer alternative", "Exclusively alternative"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "astrology_view",
        group: "astrology_view",
        display: "View on Astrology",
        category: Category::Beliefs,
        value_question: "What's your view on astrology?",
        range_question: "What view on astrology do you want your partner to have?",
        labels: Some(&["It's all nonsense", "It's fun but not serious", "Balanced approach", "I believe in it", "I plan my life around it"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "sex_work_legalization_view",
        group: "sex_work_legalization_view",
        display: "Sex Work Legalization",
        category: Category::Beliefs,
        value_question: "What's your view on the legalization of sex work (prostitution)?",
        range_question: "What view on the legalization of sex work do you want your partner to have?",
        max: 6,
        labels: Some(&["It should be punishable by death", "It should be illegal", "It should be decriminalized", "It should be legalized", "It should be regulated", "It should be a government-run service", "It should be mandatory"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "gun_control_view",
        group: "gun_control_view",
        display: "Gun Control",
        category: Category::Beliefs,
        value_question: "What's your view on gun control?",
        range_question: "What view on gun control do you want your partner to have?",
        max: 5,
        labels: Some(&["Any object that is reasonably sharp should be confiscated by autonomous government drones", "Guns should be banned", "Guns should be heavily restricted, eg. only for hunting", "Guns should be available with background checks", "Guns should be available to all", "Gun ownership should be mandatory"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "death_penalty_view",
        group: "death_penalty_view",
        display: "Death Penalty",
        category: Category::Beliefs,
        value_question: "What's your view on the death penalty?",
        range_question: "What view on the death penalty do you want your partner to have?",
        max: 3,
        labels: Some(&["It should be abolished", "It should be used only in extreme cases", "It should be used at the judge's discretion", "You break the law you get the saw"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "abortion_view",
        group: "abortion_view",
        display: "Abortion",
        category: Category::Beliefs,
        value_question: "What's your view on abortion?",
        range_question: "What view on abortion do you want your partner to have?",
        labels: Some(&["It should be punishable by death", "It should be illegal", "It should be heavily restricted", "It should be available with restrictions", "It should be available on demand"]),
        ..default_preference_config()
    },
    // Lifestyle Category
    PreferenceConfig {
        name: "number_of_children",
        group: "number_of_children",
        display: "Number of Children You Have",
        category: Category::Lifestyle,
        value_question: "How many children do you have?",
        range_question: "How many children do you want your partner to have?",
        max: 10,
        mean: 1.0,
        std_dev: 1.0,
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "number_of_dogs",
        group: "number_of_dogs",
        display: "Number of Dogs You Have",
        category: Category::Lifestyle,
        value_question: "How many dogs do you have?",
        range_question: "How many dogs do you want your partner to have?",
        max: 10,
        mean: 0.0,
        std_dev: 1.0,
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "number_of_cats",
        group: "number_of_cats",
        display: "Number of Cats You Have",
        category: Category::Lifestyle,
        value_question: "How many cats do you have?",
        range_question: "How many cats do you want your partner to have?",
        max: 10,
        mean: 0.0,
        std_dev: 1.0,
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "extroversion_level",
        group: "extroversion_level",
        display: "Extroversion Level",
        category: Category::Lifestyle,
        value_question: "How extroverted are you?",
        range_question: "How extroverted do you want your partner to be?",
        labels: Some(&[
            "Introvert",
            "Ambivert",
            "Average",
            "Extrovert",
            "Life of the party",
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "how_cleanly_are_you",
        group: "how_cleanly_are_you",
        display: "How Cleanly Are You",
        category: Category::Lifestyle,
        value_question: "How cleanly are you?",
        range_question: "How cleanly do you want your partner to be?",
        labels: Some(&[
            "Slob",
            "Average",
            "Clean",
            "Neat freak",
            "Obsessive-compulsive",
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "hoarder_level",
        group: "hoarder_level",
        display: "Hoarder Level",
        category: Category::Lifestyle,
        value_question: "How much of a hoarder are you?",
        range_question: "How much of a hoarder do you want your partner to be?",
        labels: Some(&["Monk", "Minimalist", "Average", "Collector", "Hoarder"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "rule_follower_level",
        group: "rule_follower_level",
        display: "Rule Following",
        category: Category::Lifestyle,
        value_question: "How much of a rule follower are you?",
        range_question: "How much of a rule follower do you want your partner to be?",
        max: 5,
        labels: Some(&["I frequently break the law and likely have a warrent out for my arrest", "Rebel", "Occasional rule breaker", "Average", "Law-abiding", "Obedient to a fault"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "work_schedule_flexibility",
        group: "work_schedule_flexibility",
        display: "Work Schedule Flexibility",
        category: Category::Lifestyle,
        value_question: "How flexible is your work schedule?",
        range_question: "How flexible would you like your partner's work schedule to be?",
        labels: Some(&["Very Rigid", "Somewhat Rigid", "Moderate", "Flexible", "Highly Flexible"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "morning_person",
        group: "morning_person",
        display: "Morning Person",
        category: Category::Misc,
        value_question: "Are you a morning person?",
        range_question: "Do you want your partner to be a morning person?",
        labels: Some(&["A date at 4pm? I'm not sure I'll be awake then", "Night owl", "Neutral", "Early bird", "4am? Heck I slept in"]),
        ..default_preference_config()
    },
    // End of Lifestyle Category

    // Diet Category
    PreferenceConfig {
        name: "vegetarianness",
        group: "vegetarianness",
        display: "Vegetarianness",
        category: Category::Diet,
        value_question: "How vegetarian are you?",
        range_question: "How vegetarian do you want your partner to be?",
        labels: Some(&[
            "Carnivore",
            "Omnivore",
            "Pescatarian",
            "Vegetarian",
            "Vegan",
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "food_adventurousness",
        group: "food_adventurousness",
        display: "Food Adventurousness",
        category: Category::Diet,
        value_question: "How adventurous are you with food?",
        range_question: "How adventurous do you want your partner to be with food?",
        labels: Some(&["Picky eater", "Comfort food lover", "Moderately adventurous", "Foodie", "Extreme culinary thrill-seeker"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "home_cooking_frequency",
        group: "home_cooking_frequency",
        display: "Home Cooking Frequency",
        category: Category::Diet,
        value_question: "How often do you cook at home?",
        range_question: "How often do you want your partner to cook at home?",
        labels: Some(&["Never", "Rarely", "A few times a week", "Most days", "Every day"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "organic_food_preference",
        group: "organic_food_preference",
        display: "Organic/Non-GMO Food Preference",
        category: Category::Diet,
        value_question: "What's your stance on organic/non-GMO foods?",
        range_question: "What stance on organic/non-GMO foods do you want your partner to have?",
        labels: Some(&["Don't care", "Prefer when available", "Moderately prefer", "Strongly prefer", "Exclusively organic/non-GMO"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "food_budget",
        group: "food_budget",
        display: "Monthly Food Budget",
        category: Category::Diet,
        value_question: "How much do you spend on food",
        range_question: "How much do you want your partner to spend on food and dining out per month?",
        max: 10,
        mean: 3.0,
        std_dev: 2.0,
        labels: Some(&[
            "My food is free",
            "$100",
            "$200",
            "$300",
            "$400",
            "$500",
            "$750",
            "$1,000",
            "$1,500",
            "$2,500",
            "$5,000",
            "$10,000+",
        ]),
        ..default_preference_config()
    },

    // Hobbies Category
    PreferenceConfig {
        name: "watching_competitive_sports_interest",
        group: "watching_competitive_sports_interest",
        display: "Interest in Watching Competitive Sports",
        category: Category::Hobbies,
        value_question: "How interested are you in watching competitive sports?",
        range_question: "How interested do you want your partner to be in watching competitive sports?",
        labels: Some(&["Hate watching", "Not interested", "Average", "Interested", "Fanatic"]),
        ..default_preference_config()
    },
    
    PreferenceConfig {
        name: "playing_competitive_sports_interest",
        group: "playing_competitive_sports_interest",
        display: "Interest in Playing Competitive Sports",
        category: Category::Hobbies,
        value_question: "How interested are you in playing competitive sports?",
        range_question: "How interested do you want your partner to be in playing competitive sports?",
        labels: Some(&["Hate playing", "Not interested", "Average", "Interested", "Fanatic"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "reading_interest",
        group: "reading_interest",
        display: "Reading Interest",
        category: Category::Hobbies,
        value_question: "How interested are you in reading?",
        range_question: "How interested do you want your partner to be in reading?",
        labels: Some(&["Can not read and does NOT want to learn", "Not interested", "Average", "Interested", "Bookworm"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "gamerness_level",
        group: "gamerness_level",
        display: "Gaming Habit and Interest",
        category: Category::Hobbies,
        value_question: "How would you describe your gaming habits and interest?",
        range_question: "What level of gaming interest and involvement would you prefer in a partner?",
        labels: Some(&[
            "Non-gamer (Never play)",
            "Casual (Occasionally play simple games)",
            "Regular (Play weekly, enjoy various games)",
            "Enthusiast (Play daily, follow gaming news)",
            "Hardcore (Competitive/streaming/game development)"
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "how_much_you_want_to_go_outside",
        group: "how_much_you_want_to_go_outside",
        display: "How Much You Want to Go Outside",
        category: Category::Hobbies,
        value_question: "How much do you want to go outside?",
        range_question: "How much do you want your partner to want to go outside?",
        labels: Some(&[
            "Agoraphobic",
            "Homebody",
            "Average",
            "Outdoorsy",
            "Wanderlust",
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "how_much_you_want_to_travel",
        group: "how_much_you_want_to_travel",
        display: "How Much You Want to Travel",
        category: Category::Hobbies,
        value_question: "How much do you want to travel?",
        range_question: "How much do you want your partner to want to travel?",
        labels: Some(&[
            "I don't want to travel",
            "Homebody",
            "Average",
            "Traveler",
            "Wanderlust",
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "hours_a_day_spent_on_social_media",
        group: "hours_a_day_spent_on_social_media",
        display: "Hours a Day Spent on Social Media",
        category: Category::Hobbies,
        value_question: "How many hours a day do you spend on social media?",
        range_question: "How many hours a day do you want your partner to spend on social media?",
        max: 24,
        mean: 2.0,
        std_dev: 2.0,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        ..default_preference_config()
    },

    // Future Category
    PreferenceConfig {
        name: "how_much_you_want_to_have_children",
        group: "how_much_you_want_to_have_children",
        display: "How Much You Want to Have Children",
        category: Category::Future,
        value_question: "How much do you want to have children?",
        range_question: "How much do you want your partner to want to have children?",
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        labels: Some(&[
            "I have self-sterilized",
            "I don't want children",
            "I don't want children now",
            "I might want children",
            "I want children",
            "I want many children",
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "how_much_you_want_to_get_married",
        group: "how_much_you_want_to_get_married",
        display: "How Much You Want to Get Married",
        category: Category::Future,
        value_question: "How much do you want to get married?",
        range_question: "How much do you want your partner to want to get married?",
        labels: Some(&[
            "I don't want to get married",
            "I don't want to get married now",
            "I might want to get married",
            "I want to get married",
            "I want to get married soon",
        ]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "retirement_age",
        group: "retirement_age",
        display: "Retirement Age",
        category: Category::Future,
        value_question: "What's your planned retirement age?",
        range_question: "What's your ideal retirement age for your partner?",
        min: 25,
        max: 75,
        mean: 60.0,
        std_dev: 5.0,
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "adoption_stance",
        group: "adoption_stance",
        display: "Stance on Adoption",
        category: Category::Future,
        value_question: "What's your stance on adopting children?",
        range_question: "What stance on adopting children do you want your partner to have?",
        labels: Some(&["Never", "Open to it", "Prefer adoption", "Only adoption", "Already adopted"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "career_path_vision",
        group: "career_path_vision",
        display: "Career Path Vision",
        category: Category::Future,
        value_question: "How do you envision your career path?",
        range_question: "How do you want your partner to envision their career path?",
        labels: Some(&["Steady job", "Frequent changes", "Entrepreneurship", "Early retirement", "Work until I drop"]),
        ..default_preference_config()
    },
     //Substances Category
    PreferenceConfig {
        name: "drinks_consumed_per_week",
        group: "drinks_consumed_per_week",
        display: "Drinks Consumed per Week",
        category: Category::Substances,
        value_question: "How many drinks do you have a week?",
        range_question: "How many drinks do you want your partner to have a week?",
        max: 50,
        mean: 5.0,
        std_dev: 5.0,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "smokes_per_day",
        group: "smokes_per_day",
        display: "Smokes per Day",
        category: Category::Substances,
        value_question: "How many cigarettes do you smoke a day?",
        range_question: "How many cigarettes do you want your partner to smoke a day?",
        max: 50,
        mean: 2.0,
        std_dev: 5.0,
        std_dev_alteration: StdDevAlteration::FromValue(Linear{slope: 1.0,
            intercept: 0.0,
        }),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "marajuana_consumed_per_week_joints",
        group: "marajuana_consumed_per_week_joints",
        display: "Marijuana Consumed per Week (Joints)",
        category: Category::Substances,
        value_question: "How much weed do you smoke a week, if you were to measure it in joints?",
        range_question: "How much weed do you want your partner to smoke a week, if they were to measure it in joints?",
        max: 50,
        mean: 2.0,
        std_dev: 2.0,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "psychedelic_use_per_year",
        group: "psychedelic_use_per_year",
        display: "Psychedelic Use per Year",
        category: Category::Substances,
        value_question: "How many times do you use psychedelics in a year?",
        range_question: "How many times do you want your partner to use psychedelics in a year?",
        max: 52,
        mean: 2.0,
        std_dev: 2.0,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        ..default_preference_config()
    },
    //End of Substances Category
    //Misc Category
    PreferenceConfig {
        name: "emoji_communication_skills",
        group: "emoji_communication_skills",
        display: "Emoji Communication Skills",
        category: Category::Lifestyle,
        value_question: "How fluent are you in emoji?",
        range_question: "How emoji-fluent do you want your partner to be?",
        labels: Some(&["🤔", "👍👎", "😀😃😄😁😆😅🤣😂", "🧠=💯% 🦄", "I Exclusively Communicate in Emoji"]),
        ..default_preference_config()
    },
    PreferenceConfig {
        name: "iphone_vs_android",
        group: "iphone_vs_android",
        display: "iPhone vs Android",
        category: Category::Misc,
        value_question: "Do you use iPhone or Android?",
        range_question: "Do you want your partner to use iPhone or Android?",
        max: 2,
        labels: Some(&["iPhone", "Depends on the year", "Android"]),
        ..default_preference_config()
    }
];

pub const PREFS_CARDINALITY: usize = 79;