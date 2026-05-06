import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TermsHeader(
              title: 'Términos de uso de AirPulse',
              subtitle: 'Última actualización: 06/05/2026',
            ),
            SizedBox(height: 16),
            _TermsSection(
              title: '1. Introducción',
              content:
                  'Lea atentamente los Términos de uso (los "Términos") ya que rigen el uso de (incluido el acceso a) los servicios personalizados de AirPulse para escuchar música y otros contenidos, incluidos todos nuestros sitios web y aplicaciones de software que incorporan o se vinculan a estos Términos (colectivamente, el "Servicio AirPulse") y toda la música, los videos, podcasts, audiolibros u otros materiales disponibles a través del Servicio AirPulse (el "Contenido").\n\n'
                  'El uso del Servicio AirPulse está sujeto a otros términos y condiciones proporcionados por AirPulse, que se incorporan a estos Términos mediante esta referencia (colectivamente, "Acuerdos").\n\n'
                  'Si se registra para el Servicio AirPulse, o si lo utiliza, acepta estos Términos. Si no está de acuerdo con estos Términos, entonces no debe usar el Servicio AirPulse ni acceder a ningún contenido.',
            ),
            _TermsSubsection(
              title: 'Proveedor de servicios',
              content:
                  'Estos Términos son entre usted y AirPulse AB, Regeringsgatan 19, 111 53, Estocolmo, Suecia.',
            ),
            _TermsSubsection(
              title: 'Requisitos de idoneidad y edad',
              content:
                  'Para utilizar el Servicio AirPulse y acceder a cualquier contenido, debe (1) tener 13 años o más, (2) tener el consentimiento de sus padres o tutores si es menor de edad en su país de origen, (3) tener el poder de celebrar un contrato vinculante con nosotros y no estar excluido de hacerlo según las leyes aplicables, y (4) residir en el país del servicio.',
            ),
            _TermsSection(
              title: '2. El Servicio AirPulse que proporcionamos',
              content: '',
            ),
            _TermsSubsection(
              title: 'Opciones de Servicio AirPulse',
              content:
                  'Ofrecemos numerosas opciones de Servicio AirPulse. Ciertas opciones se ofrecen sin costo, mientras que otras opciones deben pagarse antes de poder acceder a ellas (las "Suscripciones pagadas"). También podemos ofrecer planes, membresías o servicios promocionales especiales.',
            ),
            _TermsSubsection(
              title: 'Pruebas',
              content:
                  'De vez en cuando, es posible que nosotros o terceros en nuestro nombre le ofrezcan pruebas de Suscripciones pagadas durante un período específico, sin costo o a una tarifa reducida (una "Prueba").',
            ),
            _TermsSubsection(
              title: 'Limitaciones y modificaciones del servicio',
              content:
                  'Utilizamos una atención y habilidad razonables para mantener el Servicio AirPulse operativo. Sin embargo, nuestras ofertas de servicios y su disponibilidad pueden cambiar de vez en cuando y estar sujetas a las leyes aplicables, sin responsabilidad para usted.',
            ),
            _TermsSection(
              title: '3. El uso del Servicio AirPulse',
              content: '',
            ),
            _TermsSubsection(
              title: 'Crear una cuenta de AirPulse',
              content:
                  'Es posible que necesite crear una cuenta de AirPulse para usar todo o parte del Servicio AirPulse. Su nombre de usuario y contraseña son solo para uso personal y deben mantenerse confidenciales.',
            ),
            _TermsSubsection(
              title: 'Pagos y cancelación',
              content:
                  'Puede comprar una suscripción pagada directamente desde AirPulse o a través de un tercero. Las Suscripciones pagadas continúan indefinidamente hasta que se cancelen. Se le cobrará de manera recurrente el primer día de cada período de facturación.\n\n'
                  'Puede cancelar su Suscripción pagada en cualquier momento iniciando sesión en su cuenta de AirPulse y siguiendo las indicaciones en la página Cuenta. La cancelación entrará en vigencia desde el final del período de facturación en el que cancela.',
            ),
            _TermsSubsection(
              title: 'Derecho de retiro',
              content:
                  'Si se registra en una Prueba, acepta que el derecho de retiro finaliza catorce (14) días después de iniciar la Prueba. Si compra una Suscripción pagada sin Prueba, acepta que tiene catorce (14) días después de su compra para retirarse por cualquier motivo.',
            ),
            _TermsSection(
              title: '4. Derechos de propiedad intelectual y contenido',
              content: '',
            ),
            _TermsSubsection(
              title: 'Contenido de usuario',
              content:
                  'Los usuarios de AirPulse pueden publicar, cargar o de otro modo aportar contenido al Servicio AirPulse ("Contenido de usuario"). Usted es el único responsable de todo el Contenido de usuario que publique.',
            ),
            _TermsSubsection(
              title: 'Licencias que nos concede',
              content:
                  'Usted conserva la propiedad de su contenido de usuario cuando lo publica en el Servicio. Sin embargo, otorga a AirPulse una licencia no exclusiva, transferible, sublicenciable, libre de regalías e irrevocable para reproducir, distribuir y utilizar dicho Contenido de usuario a través de cualquier medio.',
            ),
            _TermsSection(
              title: '5. Atención al cliente, información, preguntas y quejas',
              content:
                  'Para recibir asistencia con preguntas relacionadas con su cuenta o pagos, utilice los recursos de Atención al cliente que aparecen en la sección Acerca de nosotros de nuestro sitio web.',
            ),
            _TermsSection(
              title: '6. Problemas y disputas',
              content: '',
            ),
            _TermsSubsection(
              title: 'Exenciones de responsabilidad de la garantía',
              content:
                  'El Servicio AirPulse se proporciona "tal cual" y "según disponibilidad", sin ninguna garantía de ningún tipo. En ningún caso AirPulse será responsable de daños indirectos, especiales, incidentales, punitivos, ejemplares o consecuentes.',
            ),
            _TermsSubsection(
              title: 'Ley aplicable y jurisdicción',
              content:
                  'A menos que las leyes obligatorias de su país de residencia exijan lo contrario, los Acuerdos están sujetos a las leyes de Suecia. Usted y AirPulse acuerdan la jurisdicción exclusiva de los tribunales de Suecia para la resolución de disputas, salvo excepciones establecidas en los Términos.',
            ),
            _TermsSubsection(
              title: 'Renuncia a demanda colectiva',
              content:
                  'Cuando lo permita la ley aplicable, usted y AirPulse acuerdan que cada uno puede presentar reclamaciones contra el otro solo en su capacidad individual y no como demandante o miembro colectivo en ninguna medida de demanda colectiva o representativa.',
            ),
            _TermsSection(
              title: '7. Acerca de estos Términos',
              content:
                  'Podemos realizar cambios a estos Términos periódicamente avisando dichos cambios por cualquier medio razonable. El uso del Servicio AirPulse después de cualquier cambio en estos Términos constituirá la aceptación de dichos cambios.\n\n'
                  'AirPulse puede asignar cualquiera o todos estos Términos y puede asignar o delegar, en su totalidad o en parte, cualquiera de sus derechos u obligaciones. No puede ceder estos Términos, en su totalidad o en parte, ni transferir o sublicenciar sus derechos bajo estos Términos a terceros.',
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TermsHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TermsHeader({required this.title, required this.subtitle});

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

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermsSection({required this.title, required this.content});

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

class _TermsSubsection extends StatelessWidget {
  final String title;
  final String content;

  const _TermsSubsection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
