public class JSONSearchDoc {

	public class SearchParameters {
		public List<SearchParameter> searchParameter;
	}

	public SearchDocuments searchDocuments;

	public class SearchDocuments {
		public String searchTemplateName;
		public SearchParameters searchParameters;
		public Integer maxDocumentsReturned;
	}

	public class SearchParameter {
		public String name;
		public String value;
		public String operator;
	}

	
	public static JSONSearchDoc parse(String json) {
		return (JSONSearchDoc) System.JSON.deserialize(json, JSONSearchDoc.class);
	}
}