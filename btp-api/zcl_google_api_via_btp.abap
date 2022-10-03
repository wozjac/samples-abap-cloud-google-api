" See https://jacekw.dev/blog/2022/google-cloud-api-call-from-abap-cloud-environment/
" Implementend & test on SAP BTP ABAP Environment 2022, free tier
CLASS zcl_google_api_via_btp DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    METHODS:
      get_signend_jwt_by_url RETURNING VALUE(result) TYPE string
                             RAISING   cx_http_dest_provider_error
                                       cx_web_http_client_error,

      get_signed_jwt_by_arrangement RETURNING VALUE(result) TYPE string
                                    RAISING   cx_http_dest_provider_error
                                              cx_web_http_client_error,

      get_project_details_json IMPORTING signed_jwt    TYPE string
                               RETURNING VALUE(result) TYPE string
                               RAISING   cx_web_http_client_error
                                         cx_http_dest_provider_error.
ENDCLASS.

CLASS zcl_google_api_via_btp IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    DATA: signed_jwt      TYPE string,
          project_details TYPE string.

    TRY.
        " Approach no 1: Call Google API using direct URLs
        signed_jwt = get_signend_jwt_by_url( ).
        project_details = get_project_details_json( signed_jwt ).

        " Approach no 2: call Google API using a communication arrangement
        signed_jwt = get_signed_jwt_by_arrangement( ).
        project_details = get_project_details_json( signed_jwt ).

        out->write( project_details ).

      CATCH cx_root INTO DATA(exception).
        out->write( exception->get_text( ) ).
    ENDTRY.

  ENDMETHOD.



  METHOD get_signend_jwt_by_url.

    " Call Google API using direct URLs

    TYPES:
      BEGIN OF ty_token_json,
        access_token  TYPE string,
        token_type    TYPE string,
        id_token      TYPE string,
        refresh_token TYPE string,
        expires_in    TYPE i,
        scope         TYPE string,
        jti           TYPE string,
      END OF ty_token_json.

    " 1. Fetch token from XSUUA jwt-backend-xsuaa, details are in the service key
    DATA(destination) = cl_http_destination_provider=>create_by_url( 
      'https://main-2f80y5al.authentication.us10.hana.ondemand.com/oauth/token' ).

    DATA(http_client) = cl_web_http_client_manager=>create_by_http_destination( destination ).
    DATA(request) = http_client->get_http_request( ).
    DATA(body) = |grant_type=client_credentials|.

    request->set_header_fields( VALUE #(
      ( name = 'Content-Type'
        value = 'application/x-www-form-urlencoded; charset=UTF-8' )
      ( name = 'Accept'
        value = 'application/json' )
      ( name = 'Content-Length'
        value = strlen( body ) ) ) ).

    request->set_authorization_basic(
      i_username = '.....'
      i_password = '....' ).

    request->append_text( body ).
    DATA(token_response) = http_client->execute( if_web_http_client=>post ).
    DATA(token) = VALUE ty_token_json( ).

    /ui2/cl_json=>deserialize(
      EXPORTING
        json = token_response->get_text( )
      CHANGING
        data = token ).

    " 2. Get signed JWT using deployed API
    destination = cl_http_destination_provider=>create_by_url( 
        'https://jwt-backend.cfapps.us10.hana.ondemand.com/sign' ).

    http_client = cl_web_http_client_manager=>create_by_http_destination( destination ).
    request = http_client->get_http_request( ).
    DATA(bearer) = |Bearer { token-access_token }|.

    request->set_header_field(
      i_name  = 'Authorization'
      i_value = bearer ).

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


  METHOD get_signed_jwt_by_arrangement.

    " Call Google API using a communication arrangement

    DATA(scenario_id) = 'ZGOOGLE_API'.
    DATA(arrangement_factory) = cl_com_arrangement_factory=>create_instance( ).

    DATA(scenario_range) = VALUE if_com_scenario_factory=>ty_query-cscn_id_range(
      ( sign = 'I' option = 'EQ' low = scenario_id ) ).

    arrangement_factory->query_ca(
      EXPORTING
        is_query = VALUE #( cscn_id_range = scenario_range )
      IMPORTING
        et_com_arrangement = DATA(arrangements) ).

    DATA(arrangement) = arrangements[ 1 ].

    DATA(destination) = cl_http_destination_provider=>create_by_comm_arrangement(
      comm_scenario  = CONV #( scenario_id )
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

    DATA(destination) = cl_http_destination_provider=>create_by_url( 
      'https://cloudresourcemanager.googleapis.com/v1/projects/jwt-call-sample' ).
      
    DATA(http_client) = cl_web_http_client_manager=>create_by_http_destination( destination ).
    DATA(request) = http_client->get_http_request( ).

    request->set_header_field(
      i_name = 'Authorization'
      i_value = |Bearer { signed_jwt }| ).

    DATA(response) = http_client->execute( if_web_http_client=>get ).
    result = response->get_text( ).

  ENDMETHOD.

ENDCLASS.