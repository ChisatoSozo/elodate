// Openapi Generator last run: : 2024-07-11T11:42:13.089993
import 'package:openapi_generator_annotations/openapi_generator_annotations.dart';

@Openapi(
    additionalProperties:
        AdditionalProperties(pubName: 'api', pubAuthor: 'Chisato'),
    inputSpec: RemoteSpec(path: "http://localhost:8080/api/spec/v2.json"),
    skipSpecValidation: true,
    generatorName: Generator.dart,
    runSourceGenOnOutput: true,
    outputDirectory: 'lib/api/pkg')
class ApiGen {}