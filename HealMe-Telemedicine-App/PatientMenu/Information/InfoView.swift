import SwiftUI
import FirebaseFirestore

struct InfoView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var medicalHistory: MedicalHistory = MedicalHistory()
    @State private var ageString: String = ""
    @State private var heightString: String = ""
    @State private var weightString: String = ""
    @State private var originalMedicalHistory: MedicalHistory = MedicalHistory()
    @State private var isEditing = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9"),
        gray: Color(hex: "808080")
    )
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            if isLoading {
                LoadingView(colors: colors)
            } else if let errorMessage = errorMessage {
                ErrorView(errorMessage: errorMessage, colors: colors, retryAction: fetchMedicalHistory)
            } else {
                ContentView(
                    medicalHistory: $medicalHistory,
                    ageString: $ageString,
                    heightString: $heightString,
                    weightString: $weightString,
                    isEditing: $isEditing,
                    colors: colors,
                    saveAction: saveMedicalHistory
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchMedicalHistory()
        }
    }
    
    // MARK: - Subviews
    
    private struct LoadingView: View {
        let colors: (red: Color, green: Color, blue: Color, background: Color, gray: Color)
        
        var body: some View {
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colors.blue))
                    .scaleEffect(1.5)
                Text("Cargando historial médico...")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
            }
        }
    }
    
    private struct ErrorView: View {
        let errorMessage: String
        let colors: (red: Color, green: Color, blue: Color, background: Color, gray: Color)
        let retryAction: () -> Void
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(colors.red)
                    .font(.system(size: 40))
                Text(errorMessage)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                Button(action: retryAction) {
                    Text("Reintentar")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(colors.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
    
    private struct ContentView: View {
        @Binding var medicalHistory: MedicalHistory
        @Binding var ageString: String
        @Binding var heightString: String
        @Binding var weightString: String
        @Binding var isEditing: Bool
        let colors: (red: Color, green: Color, blue: Color, background: Color, gray: Color)
        let saveAction: () -> Void
        
        var body: some View {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            Text("Historial Médico")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(.black)
                            Text("Actualiza tu historial:")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 35)
                        .padding(.bottom, 25)
                        
                        MedicalHistoryTable(
                            medicalHistory: $medicalHistory,
                            ageString: $ageString,
                            heightString: $heightString,
                            weightString: $weightString,
                            isEditing: isEditing,
                            colors: colors
                        )
                    }
                }
                
                // Conditional button display at the bottom
                if isEditing {
                    EditingButtons(
                        saveAction: saveAction,
                        cancelAction: { isEditing = false },
                        colors: colors
                    )
                } else {
                    EditButton(isEditing: $isEditing, colors: colors)
                }
            }
        }
    }
    
    private struct MedicalHistoryTable: View {
        @Binding var medicalHistory: MedicalHistory
        @Binding var ageString: String
        @Binding var heightString: String
        @Binding var weightString: String
        let isEditing: Bool
        let colors: (red: Color, green: Color, blue: Color, background: Color, gray: Color)
        
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Text("Concepto")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(colors.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Valor")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color.white)
                
                Divider()
                    .background(colors.gray.opacity(0.3))
                
                HistoryField(label: "Edad", value: $ageString, isEditing: isEditing, type: .number)
                Divider().background(colors.gray.opacity(0.3))
                HistoryField(label: "Alergias", value: $medicalHistory.allergies, isEditing: isEditing, type: .text)
                Divider().background(colors.gray.opacity(0.3))
                HistoryField(label: "Tipo de sangre", value: $medicalHistory.bloodType, isEditing: isEditing, type: .text)
                Divider().background(colors.gray.opacity(0.3))
                HistoryField(label: "Dieta", value: $medicalHistory.diet, isEditing: isEditing, type: .text)
                Divider().background(colors.gray.opacity(0.3))
                HistoryField(label: "Ejercicio", value: $medicalHistory.exercise, isEditing: isEditing, type: .text)
                Divider().background(colors.gray.opacity(0.3))
                HistoryField(label: "Género", value: $medicalHistory.gender, isEditing: isEditing, type: .text)
                Divider().background(colors.gray.opacity(0.3))
                HistoryField(label: "Altura (cm)", value: $heightString, isEditing: isEditing, type: .decimal)
                Divider().background(colors.gray.opacity(0.3))
                HistoryField(label: "Peso (kg)", value: $weightString, isEditing: isEditing, type: .decimal)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colors.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 17)
        }
    }
    
    private struct EditingButtons: View {
        let saveAction: () -> Void
        let cancelAction: () -> Void
        let colors: (red: Color, green: Color, blue: Color, background: Color, gray: Color)
        
        var body: some View {
            HStack(spacing: 16) {
                Button(action: saveAction) {
                    Text("Guardar")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: cancelAction) {
                    Text("Cancelar")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    private struct EditButton: View {
        @Binding var isEditing: Bool
        let colors: (red: Color, green: Color, blue: Color, background: Color, gray: Color)
        
        var body: some View {
            Button(action: { isEditing = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                    Text("Editar historial")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(colors.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Methods
    
    private func fetchMedicalHistory() {
        guard let userId = authViewModel.currentUserId else {
            errorMessage = "No se encontró el usuario autenticado."
            isLoading = false
            print("Error: No userId found in AuthViewModel")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        db.collection("patients").document(userId).getDocument { (document, error) in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Error al cargar el historial: \(error.localizedDescription)"
                    print("Firestore error: \(error)")
                    return
                }
                
                guard let document = document, document.exists, let data = document.data() else {
                    errorMessage = "No se encontró el historial médico."
                    print("No medical history found for userId: \(userId)")
                    return
                }
                
                medicalHistory = MedicalHistory(
                    age: data["age"] as? Int ?? 0,
                    allergies: data["allergies"] as? String ?? "",
                    bloodType: data["bloodType"] as? String ?? "",
                    diet: data["diet"] as? String ?? "",
                    exercise: data["exercise"] as? String ?? "",
                    gender: data["gender"] as? String ?? "",
                    height: data["height"] as? Double ?? 0.0,
                    weight: data["weight"] as? Double ?? 0.0
                )
                originalMedicalHistory = medicalHistory
                ageString = medicalHistory.age == 0 ? "" : String(medicalHistory.age)
                heightString = medicalHistory.height == 0.0 ? "" : String(format: "%.0f", medicalHistory.height)
                weightString = medicalHistory.weight == 0.0 ? "" : String(format: "%.1f", medicalHistory.weight)
                print("Medical history loaded: \(medicalHistory), ageString: \(ageString), heightString: \(heightString), weightString: \(weightString)")
            }
        }
    }
    
    private func saveMedicalHistory() {
        guard let userId = authViewModel.currentUserId else {
            errorMessage = "No se encontró el usuario autenticado."
            print("Error: No userId found in AuthViewModel")
            return
        }
        
        var data: [String: Any] = [:]
        var errors: [String] = []
        
        if ageString != (originalMedicalHistory.age == 0 ? "" : String(originalMedicalHistory.age)) {
            guard let age = Int(ageString), age >= 0, age <= 120 else {
                errors.append("La edad debe ser un número entre 0 y 120.")
                print("Invalid age input: \(ageString)")
                return
            }
            medicalHistory.age = age
            if age != 0 { data["age"] = age }
        } else {
            medicalHistory.age = originalMedicalHistory.age
        }
        
        if heightString != (originalMedicalHistory.height == 0.0 ? "" : String(format: "%.0f", originalMedicalHistory.height)) {
            guard let heightCm = Double(heightString.replacingOccurrences(of: ",", with: ".")), heightCm >= 50, heightCm <= 250 else {
                errors.append("La altura debe ser un número entre 50 y 250 cm.")
                print("Invalid height input: \(heightString)")
                return
            }
            medicalHistory.height = heightCm
            if medicalHistory.height != 0.0 { data["height"] = medicalHistory.height }
        } else {
            medicalHistory.height = originalMedicalHistory.height
        }
        
        if weightString != (originalMedicalHistory.weight == 0.0 ? "" : String(format: "%.1f", originalMedicalHistory.weight)) {
            guard let weight = Double(weightString.replacingOccurrences(of: ",", with: ".")), weight >= 10, weight <= 300 else {
                errors.append("El peso debe ser un número entre 10 y 300 kg.")
                print("Invalid weight input: \(weightString)")
                return
            }
            medicalHistory.weight = weight
            if weight != 0.0 { data["weight"] = weight }
        } else {
            medicalHistory.weight = originalMedicalHistory.weight
        }
        
        if medicalHistory.allergies != originalMedicalHistory.allergies, !medicalHistory.allergies.isEmpty {
            data["allergies"] = medicalHistory.allergies
        }
        if medicalHistory.bloodType != originalMedicalHistory.bloodType, !medicalHistory.bloodType.isEmpty {
            data["bloodType"] = medicalHistory.bloodType
        }
        if medicalHistory.diet != originalMedicalHistory.diet, !medicalHistory.diet.isEmpty {
            data["diet"] = medicalHistory.diet
        }
        if medicalHistory.exercise != originalMedicalHistory.exercise, !medicalHistory.exercise.isEmpty {
            data["exercise"] = medicalHistory.exercise
        }
        if medicalHistory.gender != originalMedicalHistory.gender, !medicalHistory.gender.isEmpty {
            data["gender"] = medicalHistory.gender
        }
        
        if !errors.isEmpty {
            errorMessage = errors.joined(separator: " ")
            isLoading = false
            return
        }
        
        guard !data.isEmpty else {
            errorMessage = "No se proporcionaron datos válidos para actualizar."
            print("No valid data to update for userId: \(userId)")
            isLoading = false
            isEditing = false
            return
        }
        
        isLoading = true
        db.collection("patients").document(userId).updateData(data) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Error al guardar el historial: \(error.localizedDescription)"
                    print("Firestore update error: \(error)")
                } else {
                    originalMedicalHistory = medicalHistory
                    isEditing = false
                    print("Medical history updated successfully for userId: \(userId), updated fields: \(data)")
                }
            }
        }
    }
}

struct MedicalHistory {
    var age: Int
    var allergies: String
    var bloodType: String
    var diet: String
    var exercise: String
    var gender: String
    var height: Double
    var weight: Double
    
    init(
        age: Int = 0,
        allergies: String = "",
        bloodType: String = "",
        diet: String = "",
        exercise: String = "",
        gender: String = "",
        height: Double = 0.0,
        weight: Double = 0.0
    ) {
        self.age = age
        self.allergies = allergies
        self.bloodType = bloodType
        self.diet = diet
        self.exercise = exercise
        self.gender = gender
        self.height = height
        self.weight = weight
    }
}

struct HistoryField: View {
    let label: String
    @Binding var value: String
    let isEditing: Bool
    let type: FieldType
    
    enum FieldType {
        case text
        case number
        case decimal
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isEditing {
                TextField("",
                    text: $value,
                    onCommit: {
                        if type == .number {
                            value = String(Int(value) ?? 0)
                        } else if type == .decimal {
                            if let doubleValue = Double(value.replacingOccurrences(of: ",", with: ".")) {
                                value = String(format: type == .decimal && label == "Altura (cm)" ? "%.0f" : "%.1f", doubleValue)
                            } else {
                                value = "0"
                            }
                        }
                    }
                )
                .keyboardType(type == .number ? .numberPad : type == .decimal ? .decimalPad : .default)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.black)
                .padding(8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            } else {
                Text(value.isEmpty ? "No registrado" : value)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(value.isEmpty ? .gray : .black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
            .environmentObject(AuthViewModel())
    }
}
