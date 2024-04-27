// Openapi Generator last run: : 2024-04-26T22:05:07.559683
import 'package:openapi_generator_annotations/openapi_generator_annotations.dart';

@Openapi(
    additionalProperties: DioProperties(pubName: 'api', pubAuthor: 'Chisato'),
    inputSpec: RemoteSpec(path: "http://localhost:8080/api/spec/v2.json"),
    skipSpecValidation: true,
    generatorName: Generator.dio,
    runSourceGenOnOutput: true,
    outputDirectory: 'lib/api/pkg')
class ApiGen {}