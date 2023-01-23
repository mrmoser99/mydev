public class JSONGetDocumentResult {

	public class DocumentData {
		public String binaryData;
        public Blob bd;
	}

	public GetDocumentResult getDocumentResult;

	public class Error {
		public String message;
	}

	public class GetDocumentResult {
		public Integer statusCode;
		public String contentType;
		public String statusCodeName;
		public Error error;
		public DocumentData documentData;
		public Integer documentLength;
	}

	
	public static JSONGetDocumentResult parse(String json) {
		return (JSONGetDocumentResult) System.JSON.deserialize(json, JSONGetDocumentResult.class);
	}
}