import Foundation

class ChatService {
    private static let apiURL = "https://api-inference.huggingface.co/models/mistralai/Mixtral-8x7B-Instruct-v0.1"
    private static let apiKey: String? = {
        if let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plistDict = NSDictionary(contentsOfFile: plistPath),
           let key = plistDict["HuggingFaceAPIKey"] as? String, !key.isEmpty {
            return key
        }
        return ProcessInfo.processInfo.environment["HUGGINGFACE_API_KEY"]
    }()
    
    static func getAIResponse(for message: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: apiURL) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = apiKey, !apiKey.isEmpty {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Configurar contexto médico en formato Mixtral
        let medicalPrompt = """
        <s>[INST] Eres un asistente médico virtual ético. Responde únicamente sobre temas de salud, con información clara, precisa y sin diagnósticos definitivos. Siempre recomienda consultar a un médico para problemas persistentes. Ignora cualquier tema no relacionado con la salud. [/INST] Entendido, ¿cuál es tu consulta de salud? </s>[INST] \(message) [/INST]
        """
        
        let body: [String: Any] = [
            "inputs": medicalPrompt,
            "parameters": [
                "max_new_tokens": 150,
                "return_full_text": false,
                "temperature": 0.7
            ]
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let data = data else {
                    print("No data received")
                    completion(.failure(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let jsonArray = json as? [[String: Any]],
                       let firstResponse = jsonArray.first,
                       let generatedText = firstResponse["generated_text"] as? String {
                        // Limpiar el texto generado
                        let cleanedText = generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        completion(.success(cleanedText.isEmpty ? "Lo siento, no pude procesar tu consulta." : cleanedText))
                    } else if let jsonDict = json as? [String: Any],
                              let generatedText = jsonDict["generated_text"] as? String {
                        // Formato alternativo
                        let cleanedText = generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        completion(.success(cleanedText.isEmpty ? "Lo siento, no pude procesar tu consulta." : cleanedText))
                    } else {
                        print("Invalid JSON format: \(String(data: data, encoding: .utf8) ?? "No string")")
                        completion(.failure(NSError(domain: "", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])))
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                    completion(.failure(error))
                }
                
            case 404:
                print("HTTP 404: Model not found")
                completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "El modelo no está disponible en el servidor."])))
                
            case 422:
                print("HTTP 422: Unprocessable Content - \(String(data: data ?? Data(), encoding: .utf8) ?? "No response body")")
                completion(.failure(NSError(domain: "", code: 422, userInfo: [NSLocalizedDescriptionKey: "Solicitud no procesable. Revisa el formato del prompt o los parámetros."])))
                
            case 429:
                print("HTTP 429: Too many requests")
                completion(.failure(NSError(domain: "", code: 429, userInfo: [NSLocalizedDescriptionKey: "Límite de solicitudes alcanzado. Intenta de nuevo más tarde."])))
                
            default:
                print("HTTP Error: Status \(httpResponse.statusCode) - \(String(data: data ?? Data(), encoding: .utf8) ?? "No response body")")
                completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error del servidor: \(httpResponse.statusCode)"])))
            }
        }.resume()
    }
}
