import Foundation

class PerformanceAnalyzer {
    static let shared = PerformanceAnalyzer()
    
    private init() {}
    
    // MARK: - Performance Metrics
    
    struct PerformanceMetrics {
        let kdRatio: Double
        let adr: Double
        let utilityEffectiveness: Double
        let headshotPercentage: Double
        let clutchSuccessRate: Double
        let economyEfficiency: Double
        
        var overallScore: Double {
            // Weighted average of all metrics
            return (kdRatio * 0.3) +
                   (adr * 0.2) +
                   (utilityEffectiveness * 0.15) +
                   (headshotPercentage * 0.15) +
                   (clutchSuccessRate * 0.1) +
                   (economyEfficiency * 0.1)
        }
    }
    
    // MARK: - Tilt Detection
    
    func detectTilt(metrics: PerformanceMetrics) -> Bool {
        // Consider a player tilted if their overall score drops significantly
        // or if specific metrics show concerning patterns
        let isKdLow = metrics.kdRatio < 0.8
        let isAdrLow = metrics.adr < 70
        let isUtilityPoor = metrics.utilityEffectiveness < 0.5
        
        return isKdLow && (isAdrLow || isUtilityPoor)
    }
    
    // MARK: - Performance Analysis
    
    func analyzePerformance(metrics: PerformanceMetrics) -> String {
        let score = metrics.overallScore
        
        switch score {
        case 0.8...:
            return "Excellent performance! Keep up the great work!"
        case 0.6..<0.8:
            return "Good performance. Focus on maintaining consistency."
        case 0.4..<0.6:
            return "Average performance. Consider reviewing your gameplay."
        case 0.2..<0.4:
            return "Below average. Take a break and reset your mindset."
        default:
            return "Poor performance. Strongly recommend taking a longer break."
        }
    }
    
    // MARK: - Improvement Suggestions
    
    func getImprovementSuggestions(metrics: PerformanceMetrics) -> [String] {
        var suggestions: [String] = []
        
        if metrics.kdRatio < 1.0 {
            suggestions.append("Work on your aim and positioning to improve K/D ratio")
        }
        
        if metrics.adr < 80 {
            suggestions.append("Focus on dealing consistent damage throughout rounds")
        }
        
        if metrics.utilityEffectiveness < 0.6 {
            suggestions.append("Practice utility usage and timing")
        }
        
        if metrics.headshotPercentage < 0.3 {
            suggestions.append("Aim for the head more consistently")
        }
        
        if metrics.clutchSuccessRate < 0.4 {
            suggestions.append("Practice clutch situations and decision making")
        }
        
        if metrics.economyEfficiency < 0.7 {
            suggestions.append("Improve your economy management and buying decisions")
        }
        
        return suggestions
    }
} 