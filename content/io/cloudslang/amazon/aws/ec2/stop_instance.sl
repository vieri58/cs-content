#   (c) Copyright 2016 Hewlett-Packard Enterprise Development Company, L.P.
#   All rights reserved. This program and the accompanying materials
#   are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
#   The Apache License is available at
#   http://www.apache.org/licenses/LICENSE-2.0
#
########################################################################################################################
#!!
#! @description: Performs an Amazon Web Services Elastic Compute Cloud (EC2) command to stop an ACTIVE server (instance)
#!               and changes its status to STOPPED. SUSPENDED servers (instances) cannot be stopped.
#!
#! @input identity: ID of the secret access key associated with your Amazon AWS account.
#! @input credential: Secret access key associated with your Amazon AWS account.
#! @input proxy_host: Proxy server used to access the provider services
#! @input proxy_port: Proxy server port used to access the provider services
#!                    Default: '8080'
#! @input proxy_username: Proxy server user name.
#! @input proxy_password: Proxy server password associated with the proxyUsername input value.
#! @input headers: String containing the headers to use for the request separated by new line (CRLF). The header
#!                 name-value pair will be separated by ":". Format: Conforming with HTTP standard for headers (RFC 2616).
#!                 Examples: "Accept:text/plain"
#! @input query_params: String containing query parameters that will be appended to the URL. The names and the values
#!                      must not be URL encoded because if they are encoded then a double encoded will occur. The
#!                      separator between name-value pairs is "&" symbol. The query name will be separated from query
#!                      value by "=".
#!                      Examples: "parameterName1=parameterValue1&parameterName2=parameterValue2"
#! @input instance_id: The ID of the server (instance) you want to stop.
#! @input force_stop: Forces the instances to stop. The instances do not have an opportunity to flush file system caches
#!                    or file system metadata. If you use this option, you must perform file system check and repair
#!                    procedures. This option is not recommended for Windows instances.
#!                    Default: ""
#! @input polling_interval: The number of seconds to wait until performing another check.
#!                          Default: 10
#! @input polling_retries: The number of retries to check if the instance is stopped.
#!                         Default: 50
#!
#! @output output: contains the state of the instance or the exception in case of failure
#! @output ip_address: The public IP address of the instance
#! @output return_code: "0" if operation was successfully executed, "-1" otherwise
#! @output exception: exception if there was an error when executing, empty otherwise
#!
#! @result SUCCESS: the server (instance) was successfully stopped
#! @result FAILURE: error stopping instance
#!!#
########################################################################################################################

namespace: io.cloudslang.amazon.aws.ec2

imports:
  instances: io.cloudslang.amazon.aws.ec2.instances
  xml: io.cloudslang.base.xml
  strings: io.cloudslang.base.strings

flow:
  name: stop_instance
  inputs:
    - identity
    - credential:
        sensitive: true
    - proxy_host:
        required: false
    - proxy_port:
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
        sensitive: true
    - headers:
        required: false
    - query_params:
        required: false
    - instance_id
    - force_stop
    - polling_interval:
        required: false
    - polling_retries:
        required: false

  workflow:
    - stop_instances:
        do:
          instances.stop_instances:
            - identity
            - credential
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - headers
            - query_params
            - instance_ids_string: '${instance_id}'
            - force_stop
        publish:
          - output: '${return_result}'
          - return_code
          - exception
        navigate:
          - SUCCESS: check_instance_state
          - FAILURE: FAILURE

    - check_instance_state:
        loop:
          for: 'step in range(0, int(get("polling_retries", 50)))'
          do:
            instances.check_instance_state:
              - identity
              - credential
              - instance_id
              - instance_state: stopped
              - proxy_host
              - proxy_port
              - proxy_username
              - proxy_password
              - polling_interval
          break:
            - SUCCESS
          publish:
            - output
            - return_code
            - exception
        navigate:
          - SUCCESS: search_and_replace
          - FAILURE: FAILURE

    - search_and_replace:
        do:
          strings.search_and_replace:
            - origin_string: '${output}'
            - text_to_replace: xmlns
            - replace_with: xhtml
        publish:
          - replaced_string
        navigate:
          - SUCCESS: parse_state
          - FAILURE: FAILURE

    - parse_state:
        do:
          xml.xpath_query:
              - xml_document: ${replaced_string}
              - xpath_query: "/*[local-name()='DescribeInstancesResponse']/*[local-name()='reservationSet']/*[local-name()='item']/*[local-name()='instancesSet']/*[local-name()='item']/*[local-name()='instanceState']/*[local-name()='name']"
              - query_type: 'value'
        publish:
            - output: ${selected_value}
            - ip_address: 'The instance is stopped. It has no IP address.'
            - return_code
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE

  outputs:
    - output
    - ip_address
    - return_code
    - exception

  results:
    - SUCCESS
    - FAILURE

extensions:
  graph:
    steps:
      stop_instances:
        x: 73
        y: 107
        navigate:
          d2ac862c-04ca-9c99-a7bc-21bffa9b47bf:
            targetId: cc5c6637-013f-0f35-b3bb-fb4c6a90902b
            port: FAILURE
      check_instance_state:
        x: 341
        y: 105
        navigate:
          a02653a1-e178-0acf-2196-4fbc24b18f42:
            targetId: cc5c6637-013f-0f35-b3bb-fb4c6a90902b
            port: FAILURE
      search_and_replace:
        x: 605
        y: 107
        navigate:
          f224eff4-5011-1b75-b0fe-cffc894296e6:
            targetId: cc5c6637-013f-0f35-b3bb-fb4c6a90902b
            port: FAILURE
      parse_state:
        x: 604
        y: 311
        navigate:
          dc2ad3b6-dd3e-6857-3733-aa7c57bd54a0:
            targetId: 6912f217-4cd7-11c7-8f89-428022b6558c
            port: SUCCESS
          01376a99-a1a5-2eac-76f2-3abb93d050a7:
            targetId: cc5c6637-013f-0f35-b3bb-fb4c6a90902b
            port: FAILURE
    results:
      SUCCESS:
        6912f217-4cd7-11c7-8f89-428022b6558c:
          x: 826
          y: 316
      FAILURE:
        cc5c6637-013f-0f35-b3bb-fb4c6a90902b:
          x: 336
          y: 311
