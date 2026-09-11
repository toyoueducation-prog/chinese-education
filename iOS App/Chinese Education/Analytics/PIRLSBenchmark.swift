import Foundation

/**
 * PIRLS BENCHMARK - International Benchmark Comparisons
 * 
 * Features:
 * - Compare student performance to PIRLS international benchmarks
 * - Grade-level percentile rankings
 * - Process-specific benchmark comparisons
 * - Visual indicators (above/below/at benchmark)
 */
// MARK: - 📊 PIRLS BENCHMARK
class PIRLSBenchmark {
    static let shared = PIRLSBenchmark()
    
    // PIRLS 2016 International Benchmarks (approximate values for reference)
    // These would ideally come from actual PIRLS data
    private let benchmarkData: [Int: GradeLevelBenchmark] = [
        1: GradeLevelBenchmark(
            level: 1,
            p25: 0.35,
            p50: 0.50,
            p75: 0.70,
            advanced: 0.85
        ),
        2: GradeLevelBenchmark(
            level: 2,
            p25: 0.40,
            p50: 0.60,
            p75: 0.75,
            advanced: 0.90
        ),
        3: GradeLevelBenchmark(
            level: 3,
            p25: 0.50,
            p50: 0.65,
            p75: 0.80,
            advanced: 0.92
        ),
        4: GradeLevelBenchmark(
            level: 4,
            p25: 0.55,
            p50: 0.70,
            p75: 0.85,
            advanced: 0.94
        ),
        5: GradeLevelBenchmark(
            level: 5,
            p25: 0.60,
            p50: 0.75,
            p75: 0.90,
            advanced: 0.96
        ),
        6: GradeLevelBenchmark(
            level: 6,
            p25: 0.65,
            p50: 0.80,
            p75: 0.95,
            advanced: 0.98
        )
    ]
    
    private init() {}
    
    // MARK: - Get Benchmark for Grade Level
    func getBenchmark(forLevel level: Int) -> GradeLevelBenchmark? {
        return benchmarkData[level]
    }
    
    // MARK: - Calculate Percentile
    /**
     * Calculates student's percentile ranking based on overall score.
     */
    func calculatePercentile(score: Double, level: Int) -> Int {
        guard let benchmark = getBenchmark(forLevel: level) else {
            return 50  // Default to median
        }
        
        if score >= benchmark.advanced {
            return 95
        } else if score >= benchmark.p75 {
            return 75
        } else if score >= benchmark.p50 {
            return 50
        } else if score >= benchmark.p25 {
            return 25
        } else {
            return 10
        }
    }
    
    // MARK: - Compare to Benchmark
    /**
     * Compares student performance to benchmarks and returns status.
     */
    func compareToBenchmark(score: Double, level: Int) -> BenchmarkComparison {
        guard let benchmark = getBenchmark(forLevel: level) else {
            return BenchmarkComparison(
                percentile: 50,
                status: .atBenchmark,
                description: "無法比較"
            )
        }
        
        let percentile = calculatePercentile(score: score, level: level)
        var status: BenchmarkStatus
        var description: String
        
        if score >= benchmark.advanced {
            status = .aboveBenchmark
            description = "表現優秀，超過國際先進水平"
        } else if score >= benchmark.p75 {
            status = .aboveBenchmark
            description = "表現良好，超過75%的國際同齡學生"
        } else if score >= benchmark.p50 {
            status = .atBenchmark
            description = "表現達到國際平均水平"
        } else if score >= benchmark.p25 {
            status = .belowBenchmark
            description = "表現低於國際平均水平，需要加強"
        } else {
            status = .belowBenchmark
            description = "表現明顯低於國際平均水平，需要重點關注"
        }
        
        return BenchmarkComparison(
            percentile: percentile,
            status: status,
            description: description
        )
    }
    
    // MARK: - Process-Specific Benchmark Comparison
    /**
     * Compares each PIRLS process to benchmarks.
     */
    func compareProcessesToBenchmark(_ profile: StudentProfile) -> [PIRLSProcess: BenchmarkComparison] {
        var comparisons: [PIRLSProcess: BenchmarkComparison] = [:]
        let level = profile.currentLevel
        
        for process in PIRLSProcess.allCases {
            if let performance = profile.pirlsAssessment.processPerformance[process] {
                let comparison = compareToBenchmark(score: performance.masteryLevel, level: level)
                comparisons[process] = comparison
            }
        }
        
        return comparisons
    }
    
    // MARK: - Get Benchmark Description
    func getBenchmarkDescription(level: Int) -> String {
        guard let benchmark = getBenchmark(forLevel: level) else {
            return "無基準數據"
        }
        
        return """
        25th百分位: \(Int(benchmark.p25 * 100))%
        50th百分位: \(Int(benchmark.p50 * 100))%
        75th百分位: \(Int(benchmark.p75 * 100))%
        先進水平: \(Int(benchmark.advanced * 100))%
        """
    }
}

// MARK: - Data Structures
struct GradeLevelBenchmark {
    let level: Int
    let p25: Double  // 25th percentile
    let p50: Double  // 50th percentile (median)
    let p75: Double  // 75th percentile
    let advanced: Double  // Advanced benchmark
}

struct BenchmarkComparison {
    let percentile: Int
    let status: BenchmarkStatus
    let description: String
}

enum BenchmarkStatus {
    case aboveBenchmark
    case atBenchmark
    case belowBenchmark
}

