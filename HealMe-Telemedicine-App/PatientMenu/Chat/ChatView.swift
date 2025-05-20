import SwiftUI

struct ChatView: View {
    @State private var messages: [(role: String, content: String)] = []
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9"),
        gray: Color(hex: "808080")
    )
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        Text("Asistente Virtual")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                        Text("¿Tienes alguna duda?")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 35)
                    .padding(.bottom, 15)
                    
                    // White container for messages and error
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(messages, id: \.content) { message in
                                    ChatBubble(
                                        role: message.role,
                                        content: message.content,
                                        isUser: message.role == "user",
                                        maxWidth: geometry.size.width * 0.75
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: geometry.size.width)
                        }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(colors.red)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colors.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    HStack {
                        TextField("Escribe tu consulta...", text: $inputText)
                            .font(.system(size: 16, design: .rounded))
                            .padding(8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .disabled(isLoading)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(isLoading ? colors.gray : colors.blue)
                                .clipShape(Circle())
                        }
                        .disabled(isLoading || inputText.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else {
            errorMessage = "Por favor, escribe una consulta."
            return
        }
        
        messages.append((role: "user", content: inputText))
        let userMessage = inputText
        inputText = ""
        
        isLoading = true
        errorMessage = nil
        
        ChatService.getAIResponse(for: userMessage) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let reply):
                    messages.append((role: "assistant", content: reply))
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    print("Hugging Face API error: \(error)")
                }
            }
        }
    }
}

struct ChatBubble: View {
    let role: String
    let content: String
    let isUser: Bool
    let maxWidth: CGFloat
    
    private let colors = (
        blue: Color(hex: "007AFE"),
        gray: Color(hex: "808080")
    )
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(content)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.black)
                .padding(12)
                .background(isUser ? colors.blue.opacity(0.2) : colors.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: maxWidth, alignment: isUser ? .trailing : .leading)
            
            if !isUser { Spacer() }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
