import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PrivacyHeader(
              title: 'Política de Privacidad de AirPulse',
              subtitle: 'Vigente a partir del 20 de abril de 2026',
            ),
            SizedBox(height: 16),
            _PrivacySection(
              title: '1. Acerca de esta Política',
              content:
                  'En esta Política de Privacidad se describe cómo procesamos tus datos personales en AirPulse AB.\n\n'
                  'Se aplica a todos los servicios de streaming de AirPulse como usuario, incluyendo tu uso de AirPulse en cualquier dispositivo, la personalización de tu experiencia de usuario, la infraestructura obligatoria para prestar nuestros servicios, la conexión de tu cuenta con otra aplicación, y nuestras opciones de streaming gratuitas y pagas.\n\n'
                  'De vez en cuando, podemos desarrollar nuevos servicios u ofrecer servicios adicionales. Esos servicios también estarán sujetos a esta Política, a menos que se indique lo contrario cuando los presentemos.',
            ),
            _PrivacySection(
              title: '2. Derechos y controles sobre tus datos personales',
              content:
                  'Muchas leyes de privacidad otorgan derechos a las personas sobre sus datos personales. Estas leyes incluyen el Reglamento General de Protección de Datos (RGPD).\n\n'
                  'Tienes los siguientes derechos sobre tus datos personales:',
            ),
            _PrivacyRightTile(
              right: 'Información',
              description:
                  'Estar informado acerca de los datos personales que procesamos sobre ti y cómo los procesamos.',
            ),
            _PrivacyRightTile(
              right: 'Acceso',
              description:
                  'Solicitar acceso a los datos personales que procesamos sobre ti. Puedes utilizar la herramienta "Descargar tus datos" en la página Privacidad de la cuenta o ponerte en contacto con nosotros.',
            ),
            _PrivacyRightTile(
              right: 'Rectificación',
              description:
                  'Solicitar que modifiquemos o actualicemos datos personales que sean imprecisos o estén incompletos. Puedes editar tus datos en la sección Editar perfil de tu cuenta.',
            ),
            _PrivacyRightTile(
              right: 'Eliminación',
              description:
                  'Solicitar que eliminemos algunos de tus datos personales. Hay situaciones en las que AirPulse no puede eliminar tus datos, por ejemplo cuando aún es necesario procesarlos para la finalidad con la que los recolectamos.',
            ),
            _PrivacyRightTile(
              right: 'Restricción',
              description:
                  'Solicitar que dejemos de procesar todos o algunos de tus datos personales, de forma temporal o permanente.',
            ),
            _PrivacyRightTile(
              right: 'Oposición',
              description:
                  'Oponerte a que procesemos tus datos personales, especialmente cuando se usan para anuncios personalizados.',
            ),
            _PrivacyRightTile(
              right: 'Portabilidad de datos',
              description:
                  'Solicitar una copia de tus datos personales en formato electrónico y transmitirlos para que se usen en el servicio de otra entidad.',
            ),
            _PrivacyRightTile(
              right: 'Revocación de consentimiento',
              description:
                  'Revocar tu consentimiento de recopilación o uso de tus datos personales en cualquier momento.',
            ),
            SizedBox(height: 8),
            _PrivacySection(
              title: '3. Datos personales que recopilamos sobre ti',
              content:
                  'Recopilamos los siguientes tipos de datos personales:\n\n'
                  '• Datos del usuario: nombre de visualización, dirección de email, contraseña, número de teléfono, fecha de nacimiento, género, dirección, país.\n\n'
                  '• Datos de uso: información sobre cómo usas AirPulse (búsquedas, historial de reproducción, playlists, configuración, interacciones), datos técnicos (URL, cookies, IP, ID del dispositivo, sistema operativo), y tu ubicación general (país, región, ciudad).\n\n'
                  '• Datos de voz: si las funciones de voz están disponibles y otorgaste el permiso.\n\n'
                  '• Datos de mensajes: si los mensajes están disponibles y elegiste usar la función.\n\n'
                  '• Datos de pagos y compras: nombre, fecha de nacimiento, método de pago, historial de pago.\n\n'
                  '• Datos de encuestas e investigaciones: datos que nos proporcionas al responder encuestas o participar en investigaciones.',
            ),
            _PrivacySection(
              title: '4. Objetivo de la utilización de tus datos personales',
              content:
                  'Utilizamos tus datos personales para:\n\n'
                  '• Proporcionar el Servicio de AirPulse de acuerdo con nuestro contrato contigo.\n'
                  '• Personalizar tu cuenta y recomendaciones de contenido.\n'
                  '• Diagnosticar, solucionar y arreglar errores del servicio.\n'
                  '• Evaluar y desarrollar nuevas funciones y tecnologías.\n'
                  '• Fines de marketing y publicidad (con tu consentimiento cuando sea requerido).\n'
                  '• Cumplir con obligaciones legales y contractuales.\n'
                  '• Mantener la seguridad del servicio y detectar fraudes.\n'
                  '• Procesar tus pagos.\n'
                  '• Realizar investigaciones y encuestas.\n\n'
                  'Los fundamentos jurídicos que amparan el procesamiento son: ejecución de contrato, interés legítimo, consentimiento y cumplimiento de obligaciones legales.',
            ),
            _PrivacySection(
              title: '5. Cómo compartimos tus datos personales',
              content:
                  'Ciertos datos estarán siempre disponibles públicamente: tu nombre de perfil, foto de perfil, playlists públicas y otro contenido que publiques.\n\n'
                  'Podemos compartir tus datos con:\n\n'
                  '• Proveedores de servicios que nos ayudan a operar el servicio.\n'
                  '• Socios de pago para procesar tus transacciones.\n'
                  '• Socios de publicidad para ofrecerte anuncios más relevantes.\n'
                  '• Otras empresas de AirPulse para operaciones comerciales diarias.\n'
                  '• Investigadores académicos en formato seudónimo.\n'
                  '• Tribunales y autoridades cuando sea legalmente requerido.\n\n'
                  'Compartimos contigo el control: solo compartiremos datos con terceros opcionales si eliges usar una función que lo requiera o si nos das permiso explícito.',
            ),
            _PrivacySection(
              title: '6. Retención de datos',
              content:
                  'Conservamos tus datos personales solo por el tiempo necesario para brindarte el Servicio de AirPulse y para finalidades comerciales legítimas y esenciales.\n\n'
                  '• Algunos datos se retienen hasta que tú los elimines.\n'
                  '• Ciertos datos expiran después de un período específico (p. ej., consultas se eliminan tras 90 días).\n'
                  '• Algunos datos se retienen hasta que se elimine tu cuenta de AirPulse.\n'
                  '• Los datos de verificación de edad se eliminan de inmediato luego de completar la verificación.',
            ),
            _PrivacySection(
              title: '7. Transferencia a otros países',
              content:
                  'Debido a la naturaleza global de nuestro negocio, AirPulse comparte tus datos personales a nivel internacional. Las transferencias a países dentro de la UE/EEE se basan en Decisiones de adecuación. Las transferencias a otros países están protegidas por Cláusulas contractuales estándar (SCC).\n\n'
                  'Implementamos protecciones adicionales como cifrado, seudonimización y evaluaciones de impacto de transferencias.',
            ),
            _PrivacySection(
              title: '8. Cómo mantenemos seguros tus datos personales',
              content:
                  'Implementamos las medidas técnicas y organizativas adecuadas para proteger la seguridad de tus datos personales, incluyendo políticas de seudonimización, cifrado, acceso y retención.\n\n'
                  'Para proteger tu cuenta, te recomendamos:\n\n'
                  '• Usar una contraseña segura exclusiva para AirPulse.\n'
                  '• Nunca compartir tu contraseña con nadie.\n'
                  '• Cerrar sesión al terminar en dispositivos compartidos.\n'
                  '• Limitar el acceso a tu computadora y navegador.',
            ),
            _PrivacySection(
              title: '9. Niños',
              content:
                  'El Servicio de AirPulse tiene un límite de edad mínima en cada país o región. Si no cumples con ese límite, no crees ni uses el Servicio estándar de AirPulse.\n\n'
                  'No recopilamos ni usamos deliberadamente datos personales de niños menores del límite de edad aplicable. Si eres padre/madre o responsable legal y te das cuenta de que tu hijo proporcionó datos personales a AirPulse, comunícate con nosotros de inmediato.',
            ),
            _PrivacySection(
              title: '10. Cambios a esta Política',
              content:
                  'Es posible que, ocasionalmente, realicemos cambios a esta Política. Cuando realicemos cambios importantes, te proporcionaremos un aviso destacado de forma adecuada, por ejemplo mostrando un aviso en el Servicio de AirPulse o enviándote una notificación por email.',
            ),
            _PrivacySection(
              title: '11. Cómo ponerte en contacto con nosotros',
              content: '',
            ),
            _PrivacyContactCard(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PrivacyHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PrivacyHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final String content;

  const _PrivacySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _PrivacyRightTile extends StatelessWidget {
  final String right;
  final String description;

  const _PrivacyRightTile({required this.right, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  right,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyContactCard extends StatelessWidget {
  const _PrivacyContactCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oficial de protección de datos',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  const Text('airpulsecorman@gmail.com'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'AirPulse AB, Regeringsgatan 19, 111 53 Estocolmo, Suecia.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
