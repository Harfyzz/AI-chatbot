//
//  ContentView.swift
//  AI chatbot
//
//  Created by Afeez Yunus on 18/06/2024.
//

import SwiftUI
import GoogleGenerativeAI
import SwiftData
import RiveRuntime

struct ContentView: View {
    
    @Environment(\.modelContext) private var context
    @Query var messages:[Message]
    
    
    let geminiModel = GenerativeModel(name: "gemini-1.5-flash", apiKey:APIKey.default )
    @State var violet = RiveViewModel(fileName: "violet", fit: .contain)
    @State var userMessage = ""
    @State var response = ""
    @State var isLoading = false
    var body: some View {
        ZStack {
            ScrollViewReader{proxy in
                ScrollView{
                    VStack{
                    ForEach (messages) { text in
                        ChatBubble(isSentByYou: text.isSentByYou, textInBubble:LocalizedStringKey( text.content), sender: text.sender, timeSent: text.time)
                            .padding(.bottom, 12)
                    }
                }.padding(.bottom, 70)
                    .padding(.top, 88)
                    if isLoading {
                        ZStack{
                            HStack{
                                HStack{
                                    Circle()
                                        .frame(height: 6)
                                    Circle()
                                        .frame(height: 6)
                                    Circle()
                                        .frame(height: 6)
                                }.foregroundStyle(.gray)
                                    .padding(8)
                                    .background(.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .scrollIndicators(.hidden)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .defaultScrollAnchor(.bottom)
                .onChange(of: messages) { oldValue, newValue in
                    if let lastMessageIndex = messages.indices.last {
                        withAnimation {
                            proxy.scrollTo(lastMessageIndex, anchor: .bottom)
                        }
                    }
                }
            }
            VStack{
            HStack{Spacer()
                VStack(spacing:8){
                    violet.view()
                        .frame(height: 44)
                    Text("Violet")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.gray)
                        .padding(.bottom)
                }
                Spacer()
            }.background(.ultraThinMaterial)
                Spacer()
                HStack(alignment:.bottom){
                    TextField("Talk to Violet...", text: $userMessage, axis: .vertical)
                        .lineLimit(4)
                        .padding(12)
                        .background(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                    Button(action: {
                        sendMessage()
                        generateResponse()
                        
                        
                    }, label: {
                        Image(systemName: "arrow.up")
                            .foregroundStyle(.white)
                            .padding()
                            .background(.blue)
                            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                    })
                    .disabled(userMessage.isEmpty ? true : false)
                }.padding(12)
                    .background(.ultraThinMaterial)
        }
        }
            .preferredColorScheme(.light)
        
        
    }
    
    func sendMessage() {
        let newMessage = Message()
        newMessage.content = userMessage
        newMessage.time = Date()
        newMessage.isSentByYou = true
        newMessage.sender = "You"
        context.insert(newMessage)
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
        
        withAnimation {
            userMessage = ""
            isLoading = true
        }
    }
    
    func generateResponse() {
        let userPrompt = messages.last?.content ?? ""
        Task {
            do {
                let geminiAnswer = try await geminiModel.generateContent(userPrompt)
                response = geminiAnswer.text ?? "Nothing to display here..."
                let geminiMessage = Message()
                geminiMessage.content = response
                geminiMessage.time = Date()
                geminiMessage.isSentByYou = false
                geminiMessage.sender = "Violet"
                context.insert(geminiMessage)
                withAnimation {
                    isLoading = false
                }
                
            } catch {
                print("something went wrong\(error.localizedDescription)")
            }
        }
        withAnimation(.bouncy){
            try? context.save()
        }
        
    }
    
    
}

#Preview {
    ContentView()
}
