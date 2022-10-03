" See https://jacekw.dev/blog/2022/google-cloud-api-call-from-abap-cloud-with-kyma
" Implementend & test on SAP BTP ABAP Environment 2022, free tier
CLASS zcl_google_api_via_kyma DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    METHODS:
      get_signed_jwt_by_arrangement RETURNING VALUE(result) TYPE string
                                    RAISING   cx_http_dest_provider_error
                                              cx_web_http_client_error,

      get_project_details_json IMPORTING signed_jwt    TYPE string
                               RETURNING VALUE(result) TYPE string
                               RAISING   cx_web_http_client_error
                                         cx_http_dest_provider_error.
ENDCLASS.

CLASS zcl_google_api_via_kyma IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    TRY.
        " Call Google API using a communication arrangement
        DATA(signed_jwt) = get_signed_jwt_by_arrangement( ).
        DATA(project_details) = get_project_details_json( signed_jwt ).

        out->write( project_details ).

      CATCH cx_root INTO DATA(exception).
        out->write( exception->get_text( ) ).
    ENDTRY.

  ENDMETHOD.

  METHOD get_signed_jwt_by_arrangement.

    " Call Google API using a communication arrangement

    DATA(communication_system) = 'JWT_SIGNER_KYMA'.
    DATA(arrangement_factory) = cl_com_arrangement_factory=>create_instance( ).

    DATA(comm_system_range) = VALUE if_com_arrangement_factory=>ty_query-cs_id_range(
      ( sign = 'I' option = 'EQ' low = communication_system ) ).

    arrangement_factory->query_ca(
      EXPORTING
        is_query = VALUE #( cs_id_range = comm_system_range )
      IMPORTING
        et_com_arrangement = DATA(arrangements) ).

    DATA(arrangement) = arrangements[ 1 ].

    DATA(destination) = cl_http_destination_provider=>create_by_comm_arrangement(
      comm_scenario  = 'ZGOOGLE_API'
      service_id     = 'ZGOOGLE_API_REST'
      comm_system_id = arrangement->get_comm_system_id( ) ).

    DATA(http_client) = cl_web_http_client_manager=>create_by_http_destination( destination ).
    DATA(request) = http_client->get_http_request( ).
    DATA(json_body) = '{ "endpoint": "https://cloudresourcemanager.googleapis.com/" }'.

    request->set_header_fields( VALUE #(
      ( name = 'Content-Type'
        value = 'application/json' )
      ( name = 'Content-Length'
        value = strlen( json_body ) ) ) ).

    request->set_text( i_text = CONV #( json_body )
                       i_length = strlen( json_body ) ).

    DATA(response) = http_client->execute( if_web_http_client=>get ).
    result = response->get_text( ).

  ENDMETHOD.

  METHOD get_project_details_json.

    DATA(destination) = cl_http_destination_provider=>create_by_url( 'https://cloudresourcemanager.googleapis.com/v1/projects/jwt-call-sample' ).
    DATA(http_client) = cl_web_http_client_manager=>create_by_http_destination( destination ).
    DATA(request) = http_client->get_http_request( ).

    request->set_header_field(
      i_name = 'Authorization'
      i_value = |Bearer { signed_jwt }| ).

    DATA(response) = http_client->execute( if_web_http_client=>get ).
    result = response->get_text( ).

  ENDMETHOD.
ENDCLASS.