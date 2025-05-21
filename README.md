# 🩺 Plataforma de Telemedicina para Zonas Rurales

Una aplicación móvil desarrollada como proyecto final de la materia de Desarrollo Móvil. Su propósito es **llevar servicios médicos de calidad a comunidades rurales y de difícil acceso**, mediante consultas remotas, acceso al historial médico y comunicación en tiempo real entre médicos y pacientes.

---

## 📱 Descripción

Esta plataforma busca solucionar la falta de servicios médicos en comunidades marginadas a través de la **telemedicina**. Permite que:

- 📞 Pacientes se conecten con médicos vía **videollamadas**.
- 📄 Médicos accedan al historial médico del paciente.
- 💊 Se generen diagnósticos y recetas que el paciente pueda recibir.

---

## 🎯 Objetivos

1. **Facilitar el acceso a servicios médicos especializados** en zonas rurales.
2. Diseñar una **interfaz sencilla y accesible** para personas con bajo nivel de alfabetización tecnológica.
3. Asegurar **funcionalidad offline y con baja conectividad**, considerando las condiciones de zonas marginadas.

---

## 👩‍⚕️ Perfil del Médico

- Nombre, especialidad, correo electrónico, teléfono, cédula médica.
- Listado de citas con pacientes: nombre, fecha y hora.
- Acceso a historial médico de pacientes.
- Registro de diagnósticos y recetas emitidas.

### Flujos del Médico:

1. **Registro e inicio de sesión.**
2. **Inicio:** Bienvenida + recordatorio de citas próximas.
3. **Citas:** Lista de citas, acceso a videollamada, formulario de diagnóstico.
4. **Pacientes:** Listado, búsqueda y visualización de historial médico.
5. **Diagnósticos:** Registro y visualización de recetas enviadas.
6. **Ajustes:** Editar perfil, cambiar contraseña, soporte, cerrar sesión.

---

## 🧑‍💻 Perfil del Paciente

- Nombre, correo electrónico, cédula, teléfono.
- Historial médico: edad, género, peso, altura, grupo sanguíneo, dieta, ejercicio, alergias o enfermedades, condiciones médicas.

### Flujos del Paciente:

1. **Registro:** Formulario de datos + historial médico.
2. **Inicio:** Bienvenida + visualización de gráficos (Charts, SwiftUICharts).
3. **Citas:** Agendar cita según disponibilidad médica (por especialidad, fecha y hora), escaneo de QR para validación (AVFoundation), unirse a videollamada (Agora).
4. **Información:** Visualización y edición del historial médico.
5. **Chat:** Chatbot con modelo Mixtral-8x7B (Hugging Face Inference API) para consultas generales.
6. **Recetas:** Visualización de recetas con diagnóstico, doctor y fecha.
7. **Ajustes:** Editar perfil, cambiar contraseña, soporte, cerrar sesión.

---

## 🧩 Tecnologías y Herramientas

- **Frontend:** Swift / XCode
- **Backend:** Firebase (autenticación y Firestore para datos)
- **Videollamadas:** [Agora SDK](https://www.agora.io/)
- **Gráficas:** SwiftUICharts, Charts
- **Chatbot:** Hugging Face Inference API (modelo `mistralai/Mixtral-8x7B-Instruct-v0.1`)
- **Escaneo QR:** AVFoundation
- **Base de datos:** Firestore (Médicos, Pacientes, Citas, Recetas)

---

## 🚧 Estado del Proyecto

✅ Funcionalidades implementadas para médicos y pacientes.  
✅ Videollamadas y chatbot operativo.  
✅ Escaneo de código QR funcional.  
✅ Soporte para notificaciones y manejo de recetas.  
🔄 En evaluación: Mejoras en accesibilidad y validaciones avanzadas.

---

## 🔐 Consideraciones

- Los médicos son dados de alta manualmente por administradores del sistema.
- El sistema asegura la privacidad de la información médica, restringiendo el acceso por rol.
- La comunicación se realiza bajo canales seguros (según las políticas de Firebase y las herramientas de terceros utilizadas).

---

## ✨ Contribuciones

Este proyecto fue desarrollado por estudiantes de **La Sabana**, como parte del curso de **Desarrollo Móvil**.

¿Quieres colaborar o extender esta plataforma? ¡Contribuciones son bienvenidas! Puedes iniciar con un fork del repositorio y seguir las buenas prácticas de PRs.

---

## 📄 Licencia

MIT License – Puedes utilizar este código para fines educativos o para ayudar a comunidades con necesidades médicas reales.

---

## 🙌 Agradecimientos

- Profesores del curso por la guía y evaluación.
- Comunidades rurales por inspirar este proyecto.
- Herramientas open-source que lo hicieron posible.

---
