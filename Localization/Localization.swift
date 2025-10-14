import Foundation

enum Localization {
    
    // MARK: - Main Screen
    static let trackersTitle = NSLocalizedString("trackers_title", comment: "Main screen title")
    static let searchPlaceholder = NSLocalizedString("search_placeholder", comment: "Search bar placeholder")
    static let filtersButton = NSLocalizedString("filters_button", comment: "Filters button title")
    static let emptyStateMessage = NSLocalizedString("empty_state_message", comment: "Empty state message")
    static let noResultsMessage = NSLocalizedString("no_results_message", comment: "No search results message")
    
    // MARK: - Statistics
    static let statisticsTitle = NSLocalizedString("statistics_title", comment: "Statistics screen title")
    static let bestPeriod = NSLocalizedString("best_period", comment: "Best period statistic")
    static let perfectDays = NSLocalizedString("perfect_days", comment: "Perfect days statistic")
    static let completedTrackers = NSLocalizedString("completed_trackers", comment: "Completed trackers statistic")
    static let averageValue = NSLocalizedString("average_value", comment: "Average value statistic")
    static let noStatsMessage = NSLocalizedString("no_stats_message", comment: "No statistics message")
    
    // MARK: - Categories
    static let categoryTitle = NSLocalizedString("category_title", comment: "Category screen title")
    static let addCategoryButton = NSLocalizedString("add_category_button", comment: "Add category button")
    static let emptyCategoriesMessage = NSLocalizedString("empty_categories_message", comment: "Empty categories message")
    static let newCategory = NSLocalizedString("new_category", comment: "New Category screen title")
    
    // MARK: - Schedule
    static let scheduleTitle = NSLocalizedString("schedule_title", comment: "Schedule screen title")
    static let everyDay = NSLocalizedString("every_day", comment: "Every day schedule")
    static let doneButton = NSLocalizedString("done_button", comment: "Done button")
    
    // MARK: - Habit Creation
    static let newHabitTitle = NSLocalizedString("new_habit_title", comment: "New habit title")
    static let editHabitTitle = NSLocalizedString("edit_habit_title", comment: "Edit habit title")
    static let trackerNamePlaceholder = NSLocalizedString("tracker_name_placeholder", comment: "Tracker name placeholder")
    static let categoryOption = NSLocalizedString("category_option", comment: "Category option")
    static let scheduleOption = NSLocalizedString("schedule_option", comment: "Schedule option")
    static let emojiSection = NSLocalizedString("emoji_section", comment: "Emoji section title")
    static let colorSection = NSLocalizedString("color_section", comment: "Color section title")
    static let cancelButton = NSLocalizedString("cancel_button", comment: "Cancel button")
    static let createButton = NSLocalizedString("create_button", comment: "Create button")
    static let saveButton = NSLocalizedString("save_button", comment: "Save button")
    
    // MARK: - Filters
    static let filtersTitle = NSLocalizedString("filters_title", comment: "Filters screen title")
    static let allTrackers = NSLocalizedString("all_trackers", comment: "All trackers filter")
    static let todayTrackers = NSLocalizedString("today_trackers", comment: "Today trackers filter")
    static let completedTrackersFilter = NSLocalizedString("completed_trackers_filter", comment: "Completed trackers filter")
    static let incompleteTrackers = NSLocalizedString("incomplete_trackers", comment: "Incomplete trackers filter")
    
    // MARK: - Context Menu
    static let editAction = NSLocalizedString("edit_action", comment: "Edit action")
    static let deleteAction = NSLocalizedString("delete_action", comment: "Delete action")
    
    // MARK: - Alerts
    static let deleteTrackerConfirmation = NSLocalizedString("delete_tracker_confirmation", comment: "Delete tracker confirmation")
    static let deleteCategoryConfirmation = NSLocalizedString("delete_category_confirmation", comment: "Delete category confirmation")
    static let deleteButton = NSLocalizedString("delete_button", comment: "Delete button")
    static let cancelAction = NSLocalizedString("cancel_action", comment: "Cancel action")
    static let emptyCategoryTitleError = NSLocalizedString("emptyCategoryTitleError", comment: "Error for empty category title")
    static let duplicateCategoryError = NSLocalizedString("duplicateCategoryError", comment: "Error for duplicate category title")
    static let error = NSLocalizedString("error", comment: "Error title")
    
    // MARK: - Category Edit
    static let editCategoryTitle = NSLocalizedString("edit_category_title", comment: "Edit category title")
    static let categoryNamePlaceholder = NSLocalizedString("category_name_placeholder", comment: "Category name placeholder")
    
    // MARK: - Onboarding
    static let onboardingTitle1 = NSLocalizedString("onboarding_title_1", comment: "First onboarding title")
    static let onboardingTitle2 = NSLocalizedString("onboarding_title_2", comment: "Second onboarding title")
    static let onboardingButton = NSLocalizedString("onboarding_button", comment: "Onboarding button")
    
    // MARK: - Days Count Formatter (используем .stringsdict)
    static func daysCount(_ count: Int) -> String {
        let format = NSLocalizedString("days_count", comment: "Days count format")
        return String.localizedStringWithFormat(format, count)
    }
    
    // MARK: - Weekdays
    static func weekdayFullName(_ weekday: Weekday) -> String {
        switch weekday {
        case .monday: return NSLocalizedString("monday", comment: "Monday full name")
        case .tuesday: return NSLocalizedString("tuesday", comment: "Tuesday full name")
        case .wednesday: return NSLocalizedString("wednesday", comment: "Wednesday full name")
        case .thursday: return NSLocalizedString("thursday", comment: "Thursday full name")
        case .friday: return NSLocalizedString("friday", comment: "Friday full name")
        case .saturday: return NSLocalizedString("saturday", comment: "Saturday full name")
        case .sunday: return NSLocalizedString("sunday", comment: "Sunday full name")
        }
    }
    
    static func weekdayShortName(_ weekday: Weekday) -> String {
        switch weekday {
        case .monday: return NSLocalizedString("monday_short", comment: "Monday short name")
        case .tuesday: return NSLocalizedString("tuesday_short", comment: "Tuesday short name")
        case .wednesday: return NSLocalizedString("wednesday_short", comment: "Wednesday short name")
        case .thursday: return NSLocalizedString("thursday_short", comment: "Thursday short name")
        case .friday: return NSLocalizedString("friday_short", comment: "Friday short name")
        case .saturday: return NSLocalizedString("saturday_short", comment: "Saturday short name")
        case .sunday: return NSLocalizedString("sunday_short", comment: "Sunday short name")
        }
    }
}
