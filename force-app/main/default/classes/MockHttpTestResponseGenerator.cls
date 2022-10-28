/**
 * Mock class for Http Response for single http callout
 */
@isTest
public class MockHttpTestResponseGenerator implements HttpCalloutMock {

	protected Integer code;
	protected String status;
	protected String bodyAsString;

	/**
	 * Instanciates MockHttpTestResponseGenerator class
	 *
	 * @param code Status Code
	 * @param status Status
	 * @param body Response Body
	 */
	public MockHttpTestResponseGenerator(Integer code, String status, String body) {
		this.code = code;
		this.status = status;
		this.bodyAsString = body;
	}

	/**
	 * Creates http response for the request passed
	 *
	 * @param req Http Request
	 * @return HTTPResponse Http Response
	 */
    public HTTPResponse respond(HTTPRequest req) {
        
        HttpResponse resp = new HttpResponse();
		resp.setStatusCode(code);
		resp.setStatus(status);
		resp.setBody(bodyAsString);

		return resp;
    }
    
}