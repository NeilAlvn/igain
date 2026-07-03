import Testing
import Foundation
import SwiftUI
@testable import Igain

/// Helper for MealType tests.
private func dateWithHour(_ hour: Int) -> Date {
    Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
}

// MARK: - NutritionCalculator

struct NutritionCalculatorTests {

    @Test func bmrMale() {
        let result = NutritionCalculator.bmr(age: 25, sex: .male, heightCm: 180, weightKg: 75)
        #expect(result == 1755)
    }

    @Test func bmrFemale() {
        let result = NutritionCalculator.bmr(age: 30, sex: .female, heightCm: 165, weightKg: 60)
        #expect(result == 1320.25)
    }

    @Test func tdee() {
        let bmr = NutritionCalculator.bmr(age: 25, sex: .male, heightCm: 180, weightKg: 75)
        let result = NutritionCalculator.tdee(age: 25, sex: .male, heightCm: 180, weightKg: 75, activityLevel: .moderate)
        #expect(result == bmr * 1.55)
    }

    @Test func targetsLoseWeight() {
        let targets = NutritionCalculator.targets(age: 30, sex: .male, heightCm: 175, weightKg: 80, activityLevel: .sedentary, goal: .lose)
        let tdee = NutritionCalculator.tdee(age: 30, sex: .male, heightCm: 175, weightKg: 80, activityLevel: .sedentary)
        let expectedCal = max(1200, (tdee - 500).rounded())
        #expect(targets.calories == expectedCal)
        let p: Double = (expectedCal * 0.30 / 4).rounded()
        let c: Double = (expectedCal * 0.40 / 4).rounded()
        let f: Double = (expectedCal * 0.30 / 9).rounded()
        #expect(targets.protein == p)
        #expect(targets.carbs == c)
        #expect(targets.fat == f)
    }

    @Test func targetsGainWeight() {
        let targets = NutritionCalculator.targets(age: 25, sex: .female, heightCm: 160, weightKg: 55, activityLevel: .active, goal: .gain)
        let tdee = NutritionCalculator.tdee(age: 25, sex: .female, heightCm: 160, weightKg: 55, activityLevel: .active)
        let expectedCal = max(1200, (tdee + 500).rounded())
        #expect(targets.calories == expectedCal)
    }

    @Test func targetsFloorAt1200() {
        let targets = NutritionCalculator.targets(age: 70, sex: .female, heightCm: 150, weightKg: 45, activityLevel: .sedentary, goal: .lose)
        #expect(targets.calories == 1200)
    }

    @Test func targetsMaintain() {
        let targets = NutritionCalculator.targets(age: 25, sex: .male, heightCm: 180, weightKg: 75, activityLevel: .moderate, goal: .maintain)
        let tdee = NutritionCalculator.tdee(age: 25, sex: .male, heightCm: 180, weightKg: 75, activityLevel: .moderate)
        #expect(targets.calories == max(1200, tdee.rounded()))
    }
}

// MARK: - ScannedFoodItem

struct ScannedFoodItemTests {

    @Test func codableRoundTrip() throws {
        let item = ScannedFoodItem(name: "Chicken Breast", portion: "150 g", calories: 250, protein: 35, carbs: 0, fat: 10)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ScannedFoodItem.self, from: data)

        #expect(decoded.name == "Chicken Breast")
        #expect(decoded.portion == "150 g")
        #expect(decoded.calories == 250)
        #expect(decoded.protein == 35)
        #expect(decoded.carbs == 0)
        #expect(decoded.fat == 10)
    }

    @Test func identifiable() {
        let item = ScannedFoodItem(name: "Rice", portion: "1 cup", calories: 200, protein: 4, carbs: 45, fat: 0.5)
        #expect(item.id == item.id)
    }

    @Test func decodeArray() throws {
        let json = """
        [{"name":"Apple","portion":"1 medium","calories":95,"protein":0.5,"carbs":25,"fat":0.3}]
        """
        let data = Data(json.utf8)
        let items = try JSONDecoder().decode([ScannedFoodItem].self, from: data)
        #expect(items.count == 1)
        #expect(items[0].name == "Apple")
        #expect(items[0].calories == 95)
    }
}

// MARK: - ScannerViewModel

@MainActor
struct ScannerViewModelTests {

    @Test func initialState() {
        let vm = ScannerViewModel()
        #expect(vm.selectedImage == nil)
        #expect(vm.isAnalyzing == false)
        #expect(vm.results.isEmpty)
        #expect(vm.errorMessage == nil)
        #expect(vm.showResults == false)
    }

    @Test func resetClearsState() {
        let vm = ScannerViewModel()
        vm.selectedImage = UIImage()
        vm.results = [ScannedFoodItem(name: "Test", portion: "1", calories: 100, protein: 1, carbs: 1, fat: 1)]
        vm.errorMessage = "error"
        vm.showResults = true

        vm.reset()

        #expect(vm.selectedImage == nil)
        #expect(vm.results.isEmpty)
        #expect(vm.errorMessage == nil)
        #expect(vm.showResults == false)
    }

    @Test func analyzeWithNoImageDoesNothing() async {
        let vm = ScannerViewModel()
        vm.selectedImage = nil
        await vm.analyze()
        #expect(vm.isAnalyzing == false)
        #expect(vm.results.isEmpty)
    }
}

// MARK: - UserProfile

struct UserProfileTests {

    @Test func initializationComputesTargets() {
        let profile = UserProfile(age: 25, sex: .male, heightCm: 180, weightKg: 75, activityLevel: .moderate, goal: .maintain)
        #expect(profile.age == 25)
        #expect(profile.sex == .male)
        #expect(profile.heightCm == 180)
        #expect(profile.weightKg == 75)
        #expect(profile.activityLevel == .moderate)
        #expect(profile.goal == .maintain)
        #expect(profile.calorieTarget > 0)
        #expect(profile.proteinTarget > 0)
        #expect(profile.carbsTarget > 0)
        #expect(profile.fatTarget > 0)
    }

    @Test func recalculateUpdatesTargets() {
        let profile = UserProfile(age: 25, sex: .male, heightCm: 180, weightKg: 75, activityLevel: .sedentary, goal: .maintain)
        let oldCal = profile.calorieTarget
        let oldProtein = profile.proteinTarget

        profile.weightKg = 90
        profile.recalculateTargets()

        #expect(profile.calorieTarget != oldCal)
        #expect(profile.proteinTarget != oldProtein)
    }

    @Test func computedPropertiesRoundTrip() {
        let profile = UserProfile(age: 30, sex: .female, heightCm: 165, weightKg: 60, activityLevel: .active, goal: .gain)
        #expect(profile.sex == .female)
        #expect(profile.activityLevel == .active)
        #expect(profile.goal == .gain)

        profile.sex = .male
        profile.activityLevel = .sedentary
        profile.goal = .lose

        #expect(profile.sex == .male)
        #expect(profile.activityLevel == .sedentary)
        #expect(profile.goal == .lose)
    }
}

// MARK: - MealType

struct MealTypeTests {

    @Test func currentReturnsBreakfastInMorning() {
        #expect(MealType.current(for: dateWithHour(8)) == .breakfast)
    }

    @Test func currentReturnsLunchAtNoon() {
        #expect(MealType.current(for: dateWithHour(12)) == .lunch)
    }

    @Test func currentReturnsDinnerAtEvening() {
        #expect(MealType.current(for: dateWithHour(19)) == .dinner)
    }

    @Test func currentReturnsSnacksLateNight() {
        #expect(MealType.current(for: dateWithHour(23)) == .snacks)
    }

    @Test func currentReturnsSnacksEarlyMorning() {
        #expect(MealType.current(for: dateWithHour(2)) == .snacks)
    }
}

// MARK: - FoodEntry

struct FoodEntryTests {

    @Test func computedProperties() {
        let entry = FoodEntry(
            name: "Oatmeal",
            mealType: .breakfast,
            servingDescription: "1 bowl",
            calories: 300,
            protein: 10,
            carbs: 50,
            fat: 5,
            source: .manual
        )
        #expect(entry.mealType == .breakfast)
        #expect(entry.source == .manual)
    }

    @Test func roundTripRawValues() {
        let entry = FoodEntry(
            name: "Chicken Salad",
            mealType: .lunch,
            servingDescription: "200 g",
            calories: 350,
            protein: 30,
            carbs: 10,
            fat: 20,
            fiber: 3,
            sugar: 2,
            source: .ai
        )
        #expect(entry.mealType == .lunch)
        #expect(entry.source == .ai)
        #expect(entry.fiber == 3)
        #expect(entry.sugar == 2)
    }

    @Test func defaults() {
        let entry = FoodEntry(
            name: "Snack",
            mealType: .snacks,
            servingDescription: "1 bar",
            calories: 150,
            protein: 5,
            carbs: 20,
            fat: 5,
            source: .barcode
        )
        #expect(entry.mealType == .snacks)
        #expect(entry.source == .barcode)
    }
}

// MARK: - ActivityLevel

struct ActivityLevelTests {

    @Test func allCasesHaveValidMultipliers() {
        for level in ActivityLevel.allCases {
            #expect(level.multiplier > 0)
        }
    }

    @Test func sedentaryMultiplier() {
        #expect(ActivityLevel.sedentary.multiplier == 1.2)
    }

    @Test func veryActiveMultiplier() {
        #expect(ActivityLevel.veryActive.multiplier == 1.9)
    }
}

// MARK: - WeightGoal

struct WeightGoalTests {

    @Test func loseAdjustmentIsNegative() {
        #expect(WeightGoal.lose.calorieAdjustment == -500)
    }

    @Test func maintainAdjustmentIsZero() {
        #expect(WeightGoal.maintain.calorieAdjustment == 0)
    }

    @Test func gainAdjustmentIsPositive() {
        #expect(WeightGoal.gain.calorieAdjustment == 500)
    }
}

// MARK: - GeminiError

struct GeminiErrorTests {

    @Test func missingAPIKeyMessage() {
        let err = GeminiError.missingAPIKey
        #expect(err.errorDescription?.contains("API key") == true)
    }

    @Test func noFoodFoundMessage() {
        let err = GeminiError.noFoodFound
        #expect(err.errorDescription?.contains("food") == true)
    }
}

// MARK: - GeminiService Response Parsing

struct GeminiServiceResponseTests {

    @Test func decodeValidResponse() throws {
        let json = """
        [{"name":"Banana","portion":"1 medium","calories":105,"protein":1.3,"carbs":27,"fat":0.4}]
        """
        let data = Data(json.utf8)
        let items = try JSONDecoder().decode([ScannedFoodItem].self, from: data)
        #expect(items.count == 1)
        #expect(items[0].name == "Banana")
        #expect(items[0].calories == 105)
    }

    @Test func decodeEmptyArray() throws {
        let data = Data("[]".utf8)
        let items = try JSONDecoder().decode([ScannedFoodItem].self, from: data)
        #expect(items.isEmpty)
    }

    @Test func decodeMultipleItems() throws {
        let json = """
        [
            {"name":"Eggs","portion":"2 eggs","calories":140,"protein":12,"carbs":1,"fat":10},
            {"name":"Toast","portion":"1 slice","calories":80,"protein":3,"carbs":15,"fat":1}
        ]
        """
        let data = Data(json.utf8)
        let items = try JSONDecoder().decode([ScannedFoodItem].self, from: data)
        #expect(items.count == 2)
    }
}
