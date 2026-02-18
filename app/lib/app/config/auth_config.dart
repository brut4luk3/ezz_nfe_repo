/// Web Client ID do Firebase para Google Sign-In.
/// Carrega de auth_config_dev.dart ou auth_config_prod.dart conforme o flavor.
/// Copie os arquivos .example e preencha com os valores reais (são gitignored).
library;

import '../../auth_config_dev.dart' as dev;
import '../../auth_config_prod.dart' as prod;

const String _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

String get kGoogleWebClientId {
  switch (_flavor) {
    case 'prod':
      return prod.kGoogleWebClientId;
    case 'dev':
    default:
      return dev.kGoogleWebClientId;
  }
}
