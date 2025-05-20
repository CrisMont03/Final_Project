//
//  AuthViewModel.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 16/05/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import FirebaseCore

class AuthViewModel: ObservableObject {
    @Published var errorMessage: String = ""
    @Published var userIsLoggedIn: Bool = false
    @Published var isDoctor: Bool = false
    @Published var doctorData: [String: Any]? = nil
    @Published var isPatientRegistrationComplete: Bool = false
    @Published var patientName: String = ""
    @Published var patientMedicalHistory: [String: Any] = [:]
    @Published var isCheckingRegistration: Bool = false
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("Firebase initialized in AuthViewModel")
        } else {
            print("Firebase already initialized")
        }

        if let user = Auth.auth().currentUser {
            print("Initial check: User already authenticated, userId=\(user.uid), email=\(user.email ?? "none")")
            self.isCheckingRegistration = true
            let email = user.email ?? ""
            self.isDoctor = email.hasSuffix("@healme.doc.co")
            if self.isDoctor {
                self.fetchDoctorData(email: email)
                self.isPatientRegistrationComplete = true
                self.patientName = ""
                self.patientMedicalHistory = [:]
                self.userIsLoggedIn = true
                self.isCheckingRegistration = false
            } else {
                self.doctorData = nil
                self.checkPatientRegistration(userId: user.uid) {
                    self.fetchPatientData(userId: user.uid)
                    self.userIsLoggedIn = true
                    self.isCheckingRegistration = false
                }
            }
        } else {
            print("Initial check: No user authenticated")
            self.isCheckingRegistration = false
        }

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            print("Auth state changed: user=\(user?.uid ?? "none"), email=\(user?.email ?? "none")")
            if let user = user, !self.userIsLoggedIn {
                self.isCheckingRegistration = true
                let email = user.email ?? ""
                self.isDoctor = email.hasSuffix("@healme.doc.co")
                print("User is doctor: \(self.isDoctor)")
                if self.isDoctor {
                    self.fetchDoctorData(email: email)
                    self.isPatientRegistrationComplete = true
                    self.patientName = ""
                    self.patientMedicalHistory = [:]
                    self.userIsLoggedIn = true
                    self.isCheckingRegistration = false
                } else {
                    self.doctorData = nil
                    self.checkPatientRegistration(userId: user.uid) {
                        self.fetchPatientData(userId: user.uid)
                        self.userIsLoggedIn = true
                        self.isCheckingRegistration = false
                    }
                }
            } else if user == nil {
                print("No user logged in, resetting state")
                self.userIsLoggedIn = false
                self.isDoctor = false
                self.doctorData = nil
                self.isPatientRegistrationComplete = false
                self.patientName = ""
                self.patientMedicalHistory = [:]
                self.errorMessage = ""
                self.isCheckingRegistration = false
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            print("Auth state listener removed")
        }
    }

    func signIn(email: String, password: String) {
        print("Attempting to sign in with email: \(email)")
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                let errorCode = (error as NSError).code
                switch errorCode {
                case AuthErrorCode.wrongPassword.rawValue:
                    self.errorMessage = "Contraseña incorrecta"
                case AuthErrorCode.invalidEmail.rawValue:
                    self.errorMessage = "Correo no válido"
                case AuthErrorCode.userNotFound.rawValue:
                    self.errorMessage = "Usuario no encontrado"
                case AuthErrorCode.networkError.rawValue:
                    self.errorMessage = "Error de red, verifica tu conexión"
                default:
                    self.errorMessage = "Error al iniciar sesión: \(error.localizedDescription)"
                }
                print("Sign-in error: \(self.errorMessage) (code: \(errorCode))")
                return
            }
            print("Sign-in successful for email: \(email)")
            self.errorMessage = ""
        }
    }

    func signUpPatient(email: String, password: String, name: String, completion: @escaping (Bool) -> Void) {
        print("Attempting to sign up patient with email: \(email), name: \(name)")
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else {
                print("Self is nil in signUpPatient")
                completion(false)
                return
            }
            if let error = error {
                let errorCode = (error as NSError).code
                switch errorCode {
                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    self.errorMessage = "El correo ya está registrado"
                case AuthErrorCode.weakPassword.rawValue:
                    self.errorMessage = "La contraseña debe tener al menos 6 caracteres"
                case AuthErrorCode.invalidEmail.rawValue:
                    self.errorMessage = "El correo no es válido"
                case AuthErrorCode.networkError.rawValue:
                    self.errorMessage = "Error de red, verifica tu conexión"
                default:
                    self.errorMessage = "Error al registrarse: \(error.localizedDescription)"
                }
                print("Sign-up error: \(self.errorMessage) (code: \(errorCode))")
                completion(false)
                return
            }
            guard let user = result?.user else {
                self.errorMessage = "No se pudo obtener el ID del usuario"
                print("Sign-up error: No user ID")
                completion(false)
                return
            }
            let patientData: [String: Any] = [
                "email": email,
                "name": name,
                "createdAt": Timestamp(),
                "isDoctor": false,
                "appointments": []
            ]
            print("Saving patient data to Firestore: \(patientData)")
            self.db.collection("patients").document(user.uid).setData(patientData) { error in
                if let error = error {
                    self.errorMessage = "Error al guardar datos del paciente: \(error.localizedDescription)"
                    print("Firestore error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                print("Patient data saved successfully for user: \(user.uid)")
                self.patientName = name
                self.isPatientRegistrationComplete = false
                self.errorMessage = ""
                completion(true)
            }
        }
    }

    func updateMedicalHistory(userId: String, age: Int, gender: String, weight: Double, height: Double, bloodType: String, diet: String, exercise: String, allergies: String, completion: @escaping (Bool) -> Void) {
        print("Updating medical history for userId: \(userId)")
        let medicalHistory: [String: Any] = [
            "age": age,
            "gender": gender,
            "weight": weight,
            "height": height,
            "bloodType": bloodType,
            "diet": diet,
            "exercise": exercise,
            "allergies": allergies,
            "updatedAt": Timestamp()
        ]
        self.db.collection("patients").document(userId).updateData(medicalHistory) { [weak self] error in
            guard let self = self else {
                print("Self is nil in updateMedicalHistory")
                completion(false)
                return
            }
            if let error = error {
                self.errorMessage = "Error al guardar historial médico: \(error.localizedDescription)"
                print("Firestore error: \(error.localizedDescription)")
                completion(false)
                return
            }
            print("Medical history updated: \(medicalHistory)")
            self.patientMedicalHistory = medicalHistory
            self.isPatientRegistrationComplete = true
            UserDefaults.standard.set(true, forKey: "isPatientRegistrationComplete_\(userId)")
            self.errorMessage = ""
            completion(true)
        }
    }

    private func checkPatientRegistration(userId: String, completion: @escaping () -> Void) {
        print("Checking patient registration for userId: \(userId)")
        if UserDefaults.standard.bool(forKey: "isPatientRegistrationComplete_\(userId)") {
            print("Patient registration complete (cached)")
            self.isPatientRegistrationComplete = true
            completion()
            return
        }
        db.collection("patients").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                completion()
                return
            }
            if let error = error {
                print("Error checking patient registration: \(error.localizedDescription)")
                self.isPatientRegistrationComplete = false
                self.errorMessage = "Error al verificar registro del paciente"
                completion()
                return
            }
            if let data = snapshot?.data(), data["age"] != nil {
                print("Patient registration complete: \(data)")
                self.isPatientRegistrationComplete = true
                UserDefaults.standard.set(true, forKey: "isPatientRegistrationComplete_\(userId)")
            } else {
                print("Patient registration incomplete")
                self.isPatientRegistrationComplete = false
            }
            completion()
        }
    }

    private func fetchPatientData(userId: String) {
        print("Fetching patient data for userId: \(userId)")
        db.collection("patients").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching patient data: \(error.localizedDescription)")
                self.errorMessage = "Error al cargar datos del paciente"
                return
            }
            guard let data = snapshot?.data() else {
                print("No patient data found for userId: \(userId)")
                self.errorMessage = "No se encontraron datos del paciente"
                return
            }
            print("Patient data fetched: \(data)")
            self.patientName = data["name"] as? String ?? ""
            self.patientMedicalHistory = data
        }
    }

    private func fetchDoctorData(email: String) {
        print("Fetching doctor data for email: \(email)")
        db.collection("doctors")
            .whereField("email", isEqualTo: email)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching doctor data: \(error.localizedDescription)")
                    self.errorMessage = "Error al buscar datos del médico"
                    self.doctorData = nil
                    return
                }
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No doctor data found for email: \(email)")
                    self.errorMessage = "No se encontró información para este médico"
                    self.doctorData = nil
                    return
                }
                self.doctorData = documents.first?.data()
                print("Doctor data fetched: \(String(describing: self.doctorData))")
                self.errorMessage = ""
            }
    }

    func findAvailableDoctor(specialty: String, date: String, hour: String, completion: @escaping (String?, String?) -> Void) {
        print("Finding available doctor for specialty: \(specialty), date: \(date), hour: \(hour)")
        db.collection("doctors")
            .whereField("specialty", isEqualTo: specialty)
            .getDocuments { (snapshot: QuerySnapshot?, error: Error?) in
                if let error = error {
                    print("Error fetching doctors: \(error.localizedDescription)")
                    completion(nil, nil)
                    return
                }
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No doctors found for specialty: \(specialty)")
                    completion(nil, nil)
                    return
                }

                for document in documents {
                    let doctorId = document.documentID
                    let doctorData = document.data()
                    let doctorName = doctorData["name"] as? String ?? "Desconocido"
                    let appointments = doctorData["appointments"] as? [[String: Any]] ?? []

                    let isAvailable = appointments.allSatisfy { appointment in
                        let apptDate = appointment["date"] as? String ?? ""
                        let apptHour = appointment["hour"] as? String ?? ""
                        return !(apptDate == date && apptHour == hour)
                    }

                    if isAvailable {
                        print("Doctor available: \(doctorName) (ID: \(doctorId))")
                        completion(doctorId, doctorName)
                        return
                    }
                }
                print("No available doctors found")
                completion(nil, nil)
            }
    }

    func createAppointment(appointment: Appointment, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUserId else {
            print("No user ID available")
            errorMessage = "No se pudo obtener el ID del usuario"
            completion(false)
            return
        }

        guard !patientName.isEmpty else {
            print("Patient name is empty")
            errorMessage = "El nombre del paciente no está disponible"
            completion(false)
            return
        }

        let patientAppointment: [String: Any] = [
            "doctorId": appointment.doctorId,
            "doctorName": appointment.doctorName,
            "specialty": appointment.specialty,
            "date": appointment.date,
            "hour": appointment.hour
        ]

        let doctorAppointment: [String: Any] = [
            "date": appointment.date,
            "hour": appointment.hour,
            "patientName": patientName
        ]

        print("Starting createAppointment for userId: \(userId), doctorId: \(appointment.doctorId), patientName: \(patientName)")

        db.collection("patients").document(userId).getDocument { snapshot, error in
            print("Checking patient document for userId: \(userId)")
            if let error = error {
                print("Error checking patient document: \(error.localizedDescription)")
                self.errorMessage = "Error al verificar datos del paciente: \(error.localizedDescription)"
                completion(false)
                return
            }

            guard snapshot?.exists == true else {
                print("Patient document does not exist for userId: \(userId)")
                self.errorMessage = "El documento del paciente no existe"
                completion(false)
                return
            }

            print("Patient document exists, checking doctor document")

            self.db.collection("doctors").document(appointment.doctorId).getDocument { snapshot, error in
                print("Checking doctor document for doctorId: \(appointment.doctorId)")
                if let error = error {
                    print("Error checking doctor document: \(error.localizedDescription)")
                    self.errorMessage = "Error al verificar datos del doctor: \(error.localizedDescription)"
                    completion(false)
                    return
                }

                guard snapshot?.exists == true else {
                    print("Doctor document does not exist for doctorId: \(appointment.doctorId)")
                    self.errorMessage = "El documento del doctor no existe"
                    completion(false)
                    return
                }

                let doctorData = snapshot?.data()
                if doctorData?["appointments"] == nil {
                    print("Initializing appointments array for doctorId: \(appointment.doctorId)")
                    self.db.collection("doctors").document(appointment.doctorId).setData([
                        "appointments": []
                    ], merge: true) { error in
                        if let error = error {
                            print("Error initializing doctor appointments array: \(error.localizedDescription)")
                            self.errorMessage = "Error al inicializar datos de citas del doctor: \(error.localizedDescription)"
                            completion(false)
                            return
                        }
                        print("Doctor appointments array initialized successfully")
                        self.updateAppointments(userId: userId, patientAppointment: patientAppointment, doctorId: appointment.doctorId, doctorAppointment: doctorAppointment, completion: completion)
                    }
                } else {
                    print("Doctor appointments array exists, proceeding to update")
                    self.updateAppointments(userId: userId, patientAppointment: patientAppointment, doctorId: appointment.doctorId, doctorAppointment: doctorAppointment, completion: completion)
                }
            }
        }
    }

    private func updateAppointments(userId: String, patientAppointment: [String: Any], doctorId: String, doctorAppointment: [String: Any], completion: @escaping (Bool) -> Void) {
        print("Updating patient appointments for userId: \(userId)")
        db.collection("patients").document(userId).updateData([
            "appointments": FieldValue.arrayUnion([patientAppointment])
        ]) { error in
            if let error = error {
                print("Error saving patient appointment: \(error.localizedDescription)")
                self.errorMessage = "Error al guardar la cita del paciente: \(error.localizedDescription)"
                completion(false)
                return
            }

            print("Patient appointment saved, updating doctor appointments for doctorId: \(doctorId)")
            self.db.collection("doctors").document(doctorId).updateData([
                "appointments": FieldValue.arrayUnion([doctorAppointment])
            ]) { error in
                if let error = error {
                    print("Error saving doctor appointment: \(error.localizedDescription)")
                    self.errorMessage = "Error al guardar la cita del doctor: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                print("Appointment created successfully")
                self.errorMessage = ""
                completion(true)
            }
        }
    }

    func fetchPatientAppointments(userId: String, completion: @escaping ([Appointment]) -> Void) {
        print("Fetching appointments for userId: \(userId)")
        db.collection("patients").document(userId).getDocument { (snapshot: DocumentSnapshot?, error: Error?) in
            if let error = error {
                print("Error fetching appointments: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let data = snapshot?.data(),
                  let appointmentsData = data["appointments"] as? [[String: Any]] else {
                print("No appointments found for userId: \(userId)")
                completion([])
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: appointmentsData)
                let appointments = try JSONDecoder().decode([Appointment].self, from: jsonData)
                completion(appointments)
            } catch {
                print("Error decoding appointments: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    func fetchDoctorAppointments(doctorId: String, completion: @escaping ([AppointmentDoctor]) -> Void) {
        print("Fetching appointments for doctorId: \(doctorId)")
        db.collection("doctors").document(doctorId).getDocument { (snapshot: DocumentSnapshot?, error: Error?) in
            if let error = error {
                print("Error fetching doctor appointments: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let data = snapshot?.data(),
                  let appointmentsData = data["appointments"] as? [[String: Any]] else {
                print("No appointments found for doctorId: \(doctorId)")
                completion([])
                return
            }
            
            let appointments = appointmentsData.compactMap { dict -> AppointmentDoctor? in
                guard let date = dict["date"] as? String,
                      let hour = dict["hour"] as? String,
                      let patientName = dict["patientName"] as? String else {
                    return nil
                }
                return AppointmentDoctor(id: UUID(), date: date, hour: hour, patientName: patientName)
            }
            
            let sortedAppointments = appointments.sorted { (appt1, appt2) in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                let date1 = dateFormatter.date(from: "\(appt1.date) \(appt1.hour)") ?? Date.distantFuture
                let date2 = dateFormatter.date(from: "\(appt2.date) \(appt2.hour)") ?? Date.distantFuture
                return date1 < date2
            }
            
            completion(sortedAppointments)
        }
    }

    func fetchPatientAppointmentId(doctorId: String, date: String, hour: String, patientName: String, completion: @escaping (String?) -> Void) {
        print("Fetching patient appointment ID for doctorId: \(doctorId), date: \(date), hour: \(hour), patientName: \(patientName)")
        
        db.collection("patients")
            .whereField("name", isEqualTo: patientName)
            .getDocuments { (snapshot: QuerySnapshot?, error: Error?) in
                if let error = error {
                    print("Error fetching patient appointment: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No patient documents found for patientName: \(patientName)")
                    self.db.collection("patients").getDocuments { (allSnapshot, allError) in
                        if let allError = allError {
                            print("Error fetching all patients: \(allError.localizedDescription)")
                        } else if let allDocs = allSnapshot?.documents {
                            print("All patient documents: \(allDocs.map { ($0.documentID, $0.data()) })")
                        }
                    }
                    completion(nil)
                    return
                }
                
                print("Found \(documents.count) patient documents for patientName: \(patientName)")
                for document in documents {
                    let patientId = document.documentID
                    let data = document.data()
                    print("Patient ID: \(patientId), Data: \(data)")
                    
                    if let appointmentsData = data["appointments"] as? [[String: Any]],
                       let matchingAppointment = appointmentsData.first(where: { appt in
                           appt["doctorId"] as? String == doctorId &&
                           appt["date"] as? String == date &&
                           appt["hour"] as? String == hour
                       }) {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: [matchingAppointment])
                            let appointments = try JSONDecoder().decode([Appointment].self, from: jsonData)
                            if let appointment = appointments.first {
                                print("Found patient appointment ID: \(appointment.id.uuidString)")
                                completion(appointment.id.uuidString)
                                return
                            }
                        } catch {
                            print("Error decoding patient appointment: \(error.localizedDescription)")
                        }
                    }
                }
                
                print("No matching appointment found in patient documents")
                completion(nil)
            }
    }
    
    func fetchChannelName(doctorId: String, date: String, hour: String, patientName: String, completion: @escaping (String?) -> Void) {
        print("Fetching channelName for doctorId: \(doctorId), date: \(date), hour: \(hour), patientName: \(patientName)")
        
        db.collection("active_calls")
            .whereField("doctorId", isEqualTo: doctorId)
            .whereField("date", isEqualTo: date)
            .whereField("hour", isEqualTo: hour)
            .whereField("patientName", isEqualTo: patientName)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching channelName: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot?.documents.first,
                      let channelName = document.data()["channelName"] as? String else {
                    print("No active call found for doctorId: \(doctorId), date: \(date), hour: \(hour), patientName: \(patientName)")
                    completion(nil)
                    return
                }
                
                print("Found channelName: \(channelName)")
                completion(channelName)
            }
    }
}

