/**
 * Mock class for Http Response for multiple http callouts
 */
@isTest
public class MultiRequestMock implements HttpCalloutMock {

	List<HttpCalloutMock> requestsList;
	Integer requestCounter;

	public MultiRequestMock(List<HttpCalloutMock> requestsList) {
		this.requestsList = requestsList;
		requestCounter = 0;
	}

	/**
	 * Creates http response for the request passed
	 *
	 * @param req Http Request
	 * @return HTTPResponse Http Response
	 */
	public HTTPResponse respond(HTTPRequest req) {
		HttpCalloutMock mock = requestsList.get(requestCounter);
        requestCounter++;
		return mock.respond(req);
	}
}