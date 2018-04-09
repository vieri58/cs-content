namespace: content.io.cloudslang.demo

operation:
    name: deploy_tomcat

    inputs:
      - input_1
      - input_2

    java_action:
      gav: 'group:artifact:version'
      class_name: DeployTomcat
      method_name: execute

    outputs:
      - output_1

    results:
      - SUCCESS: ${returnCode == '0'}
      - FAILURE