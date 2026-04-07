//
//  summarize.swift
//  wellSync
//
//  Created by Rishika Mittal on 03/04/26.
//

import UIKit
import CoreImage
import FirebaseCore
import FirebaseAILogic

class Summarise: UIViewController {
    
    static let summarise = Summarise()
    
    lazy var model: GenerativeModel = {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        return ai.generativeModel(modelName: "gemini-3-flash-preview")
    }()
    
    func extractAndSummarizeWithGemini(image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Could not process image.")
            return "Could not process image"
        }
            // Step 1 — Create inline image data for Gemini
        let imagePart = InlineDataPart(data: imageData, mimeType: "image/jpeg")

            // Step 2 — Prompt for RAW TEXT extraction
        let extractPrompt = """
        This is a photo of a handwritten journal page.
        Please extract ALL the handwritten text as written. some words may be incomplete/or is not an actual word like comparnt, meaning compartment.
        there may be some words which do not make sense in the sentence, as they miss some letters or are miss spelled, so correct them.
        Preserve line breaks. Ignore any watermarks.
        Do NOT add any numbering, bullet points, or formatting.
        Do not paraphrase or remove or add any information from your side.
        Only return the extracted text, nothing else.
        """

        await MainActor.run { print("✍️ Extracting handwriting...") }

            // Step 3 — Send image + prompt to Gemini
        let extractResponse = try await model.generateContent(extractPrompt, imagePart)
        let extractedText = extractResponse.text ?? "No text found."

            // Step 4 — Now ask Gemini to summarize the extracted text
        await MainActor.run { print("🧠 Summarizing...") }

        let summaryPrompt = """
        Here is text extracted from a handwritten journal entry:

        \(extractedText)

        Please provide a clear, concise summary in 3-5 sentences.
        Focus on the key points and main ideas.
        """

        let summaryResponse = try await model.generateContent(summaryPrompt)
        return "\n\(summaryResponse.text ?? "Could not summarize.")"

    }
}
