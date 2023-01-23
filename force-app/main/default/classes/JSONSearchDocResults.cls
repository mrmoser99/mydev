public class JSONSearchDocResults {

	public SearchDocumentsResult searchDocumentsResult;

	public class Error {
		public String message;
	}

	public class IndexValues {
		public List<IndexValue> indexValue;
	}

	public class IndexValue {
		public String value;
		public String name;
	}

	public class SearchDocumentsResult {
		public Integer statusCode;
		public String statusCodeName;
		public Error error;
		public MatchingDocuments matchingDocuments;
	}

	public class MatchingDocuments {
		public List<DocumentInfo> documentInfo;
	}

	public class DocumentInfo {
		public String din;
		public Double timeStamp;
		public String itemClass;
		public IndexValues indexValues;
		public String url;
	}

	public static JSONSearchDocResults parse(String json) {
		return (JSONSearchDocResults) System.JSON.deserialize(json, JSONSearchDocResults.class);
	}
}