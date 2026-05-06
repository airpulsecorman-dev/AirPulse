import 'package:flutter/material.dart';

class IntellectualPropertyPage extends StatelessWidget {
  const IntellectualPropertyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propiedad Intelectual'),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IPHeader(
              title: 'Política de propiedad intelectual de AirPulse',
            ),
            SizedBox(height: 16),
            _IPSection(
              title: '1. Acerca de esta Política',
              content:
                  'Esta Política de propiedad intelectual describe cómo manejamos los reclamos de infracción de propiedad intelectual en los sitios web, las aplicaciones y los servicios de AirPulse (el "Servicio de AirPulse").\n\n'
                  'AirPulse respeta los derechos de propiedad intelectual y espera que sus usuarios hagan lo mismo. Cuando utilizan el Servicio de AirPulse, los usuarios deben cumplir con las Pautas del usuario de AirPulse, así como con las leyes, las reglas y los reglamentos pertinentes, y respetar la propiedad intelectual, la privacidad y otros derechos de terceros.',
            ),
            _IPSection(
              title: '2. Derechos de autor',
              content: '',
            ),
            _IPSubsection(
              title: 'Qué son los Derechos de autor',
              content:
                  'Los Derechos de autor son derechos legales que buscan proteger obras originales de autoría (por ejemplo, música, obras de arte, libros). El propietario de Derechos de autor tiene el derecho exclusivo de hacer ciertos usos de una obra creativa, lo que incluye copiar dicha obra, distribuirla y exhibirla.\n\n'
                  'En general, los Derechos de autor protegen la expresión original, no datos ni ideas. Por lo general, los Derechos de autor no protegen cosas como nombres, títulos ni eslóganes.\n\n'
                  'Existen algunas excepciones a los Derechos de autor. Por ejemplo, en ciertos países, una persona que no sea titular de Derechos de autor puede tener permitido utilizarlos si dicho uso es justo, como lo sería para fines de revisión, crítica o parodia.',
            ),
            _IPSubsection(
              title: 'Cómo denunciar infracciones de Derechos de autor',
              content:
                  'Si usted es titular o agente de Derechos de autor y cree que algún material disponible a través de los Servicios de AirPulse infringe su trabajo protegido, puede enviar un aviso de supuesta infracción al agente de Derechos de autor designado de AirPulse con la siguiente información:\n\n'
                  '• Identificación específica de cada obra protegida que se haya infringido.\n'
                  '• Una descripción de dónde se encuentra el material infractor en los Servicios de AirPulse (con URL si es posible).\n'
                  '• Información de contacto: nombre completo, dirección, teléfono y correo electrónico.\n'
                  '• Declaración de buena fe de que el uso no está autorizado por el titular, su agente o la ley.\n'
                  '• Declaración de que la información en la notificación es precisa, bajo pena de perjurio.\n'
                  '• Firma física o electrónica del propietario o persona autorizada.\n'
                  '• Declaración de que comprende que su información se proporcionará a la parte supuestamente infractora.',
            ),
            _IPContactCard(),
            _IPSection(
              title: '3. Marca comercial',
              content: '',
            ),
            _IPSubsection(
              title: 'Qué es una Marca comercial',
              content:
                  'Una Marca comercial es una palabra, un eslogan, un símbolo o un diseño (por ejemplo, nombre de marca, logotipo) que distingue los productos o servicios ofrecidos por una persona, un grupo o una empresa de los ofrecidos por otra.\n\n'
                  'Por lo general, la ley de Marcas comerciales busca evitar la confusión entre los consumidores sobre quién proporciona o está afiliado a un producto o servicio.',
            ),
            _IPSubsection(
              title: 'Cómo denunciar una infracción de Marca comercial',
              content:
                  'Si usted es titular o agente de una Marca comercial y cree que algún material disponible a través de los Servicios de AirPulse infringe sus derechos, puede enviar un aviso de supuesta infracción a través de los canales de contacto habilitados.\n\n'
                  'AirPulse puede transferir su nombre y dirección de correo electrónico a la parte presuntamente infractora, y retenerla durante el tiempo que sea necesario para fines legales. AirPulse también tiene una política para terminar, en las circunstancias que correspondan, las cuentas de infractores reincidentes.',
            ),
            _IPSection(
              title: '4. Cómo manejamos los reclamos',
              content:
                  'AirPulse revisa los reclamos que se reciben a través de los canales identificados. Cuando recibimos una reclamación, la evaluamos y tomamos las medidas correspondientes, que pueden incluir la eliminación del contenido denunciado o la desactivación del acceso en uno o más países específicos.\n\n'
                  'Se puede eliminar cualquier contenido que infrinja los Derechos de autor o de Marca comercial de otra persona. AirPulse también tiene una política para infractores reincidentes, según la cual, a un usuario o creador responsable de varias infracciones se le puede terminar su cuenta.\n\n'
                  'Si cree que se han tomado medidas por error contra su contenido o cuenta, tendrá la oportunidad de presentar una apelación. Las instrucciones sobre cómo apelar se encuentran en la correspondencia por correo electrónico que le enviaremos con respecto al reclamo.\n\n'
                  'Además de las denuncias de los usuarios y titulares de derechos, utilizamos una combinación de señales manuales y automatizadas para detectar y eliminar contenido que pueda infringir la propiedad intelectual de otra persona.',
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _IPHeader extends StatelessWidget {
  final String title;

  const _IPHeader({required this.title});

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
        const Divider(height: 24),
      ],
    );
  }
}

class _IPSection extends StatelessWidget {
  final String title;
  final String content;

  const _IPSection({required this.title, required this.content});

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

class _IPSubsection extends StatelessWidget {
  final String title;
  final String content;

  const _IPSubsection({required this.title, required this.content});

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

class _IPContactCard extends StatelessWidget {
  const _IPContactCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agente de Derechos de autor designado',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('AirPulse EC Inc.'),
              const Text('Attn: Legal Department, Copyright Agent'),
              const Text(
                'Guayaquil, 12/2 Vía Daule, Bastión Popular Bloque 6, Callejón 25.',
              ),
              const SizedBox(height: 4),
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
            ],
          ),
        ),
      ),
    );
  }
}
