component displayname="login" author="Jason Everling" hint="Functions related to authentication" output="false"
{

    db = CreateObject("component", "database");
    utils = CreateObject("component", "utils");

    /**
    * Returns true or false if api token is valid, follows api* pattern
    *
    * @author Jason A. Everling
    * @token API Token, can either be sent in body or header
    * @return boolean true or false
    */
    public function apiAuthorization(required string token)
    {
        if (len(rtrim(token)) == 0) {
            throw(type = "Invalid Token", message = "Token is required");
        }
        stmt = "SELECT s.user_id, s.disabled
                FROM security s
                WHERE s.user_id = :user AND CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, s.password)) = :token AND s.disabled = '0'";
        params = [["user", session.apiUser],["token", token]];
        result = db.execQuery(stmt, params);
        if (result.RecordCount > 0) {
            return true;
        }
        return false;
    }

    /**
    * Disables an account login
    *
    * @author Jason A. Everling
    * @user The account to be disabled
    * @return boolean true or false
    */
    public function disableLogin(required string user)
    {
        error = false;
        params = [["user", user]];
        stmt = "UPDATE security SET disabled = 1 WHERE user_id = :user";
        try {
            db.execQuery(stmt, params);
        } catch (any e) {
            error = true;
        }
        if (error == false) {
            return true;
        }
        return false;
    }

    /**
    * Returns true or false if credentials are valid
    *
    * @author Jason A. Everling
    * @user Username
    * @password Password
    * @type Type of username, either soc_sec, ldap, or email
    * @credential Set to "security" if validating security credentials, blank otherwise
    * @return boolean true or false
    */
    public function verifyCredentials(required string user, required string password, required string type, string credential)
    {

        isSecurity = false;
        if (credential == "security") {
            isSecurity = true;
        }
        if (type == "soc_sec") {
            filter = "WHERE n.soc_sec = :user AND n.pin = :password AND n.disabled = '0'";
        } else if (type == "ldap") {
            filter = "WHERE n.ldap_id = :user AND n.pin = :password AND n.disabled = '0'";
        } else if (type == "email") {
            filter = "INNER JOIN address a ON n.soc_sec = a.soc_sec AND a.preferred = '1' WHERE a.e_mail = :user AND n.pin = :password AND n.disabled = '0'";
        } else {
            return false;
        }
        params = [["user", session.apiUser],["password", password]];
        stmt = "SELECT n.soc_sec, n.disabled, CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, n.PIN)) AS pin FROM name n " & filter;
        if (isSecurity) {
            stmt = "SELECT s.user_id, s.disabled, CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, s.password)) AS password
                    FROM security s
                    WHERE s.user_id = :user AND CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, s.password)) = :password AND s.disabled = '0'";
        }
        result = db.execQuery(stmt, params);
        if (result.RecordCount > 0) {
            return true;
        }
        return false;
    }
}
