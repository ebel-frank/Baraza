/// Set to false once a backend is hosted and reachable, to make Sign In and
/// Register actually call the API again. While true, both screens skip the
/// network call entirely and just create a local session so the rest of the
/// app's UI can be navigated/tested without a backend.
const kSkipAuthApiCalls = false;
