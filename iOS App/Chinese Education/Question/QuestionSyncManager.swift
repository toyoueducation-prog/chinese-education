import Foundation

class QuestionSyncManager {
    static let shared = QuestionSyncManager()
    private let cacheFileName = "question_cache.json"

    // MARK: - Fetch Online Questions Only When Necessary
    func fetchQuestionsFromServer() {
        guard let url = URL(string: "https://jkcorp.pythonanywhere.com/questionbank") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch questions from server")
                return
            }

            do {
                let fetchedQuestions = try JSONDecoder().decode([Question].self, from: data)
                self.saveToCache(fetchedQuestions)
            } catch {
                print("Error decoding questions: \(error)")
            }
        }.resume()
    }

    // MARK: - Save Fetched Questions Locally
    private func saveToCache(_ questions: [Question]) {
        let fileURL = getCacheFilePath()
        do {
            let encodedData = try JSONEncoder().encode(questions)
            try encodedData.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save questions locally: \(error)")
        }
    }

    // MARK: - Load Cached Questions
    func loadCachedQuestions() -> [Question] {
        let fileURL = getCacheFilePath()
        do {
            let data = try Data(contentsOf: fileURL)
            let questions = try JSONDecoder().decode([Question].self, from: data)
            return questions
        } catch {
            print("Failed to load cached questions: \(error)")
            return []
        }
    }

    // MARK: - Get Cache File Path
    private func getCacheFilePath() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("question_cache.json")
    }
}
