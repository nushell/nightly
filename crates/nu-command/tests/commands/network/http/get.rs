use mockito::Server;
use nu_test_support::{nu, pipeline};

#[test]
fn http_get_is_success() {
    let mut server = Server::new();

    let _mock = server.mock("GET", "/").with_body("foo").create();

    let actual = nu!(pipeline(
        format!(
            r#"
        http get {url}
        "#,
            url = server.url()
        )
        .as_str()
    ));

    assert_eq!(actual.out, "foo")
}

#[test]
fn http_get_failed_due_to_server_error() {
    let mut server = Server::new();

    let _mock = server.mock("GET", "/").with_status(400).create();

    let actual = nu!(pipeline(
        format!(
            r#"
        http get {url}
        "#,
            url = server.url()
        )
        .as_str()
    ));

    assert!(actual.err.contains("Bad request (400)"))
}

#[test]
fn http_get_with_accept_errors() {
    let mut server = Server::new();

    let _mock = server
        .mock("GET", "/")
        .with_status(400)
        .with_body("error body")
        .create();

    let actual = nu!(pipeline(
        format!(
            r#"
        http get -e {url}
        "#,
            url = server.url()
        )
        .as_str()
    ));

    assert!(actual.out.contains("error body"))
}

#[test]
fn http_get_with_accept_errors_and_full_raw_response() {
    let mut server = Server::new();

    let _mock = server
        .mock("GET", "/")
        .with_status(400)
        .with_body("error body")
        .create();

    let actual = nu!(pipeline(
        format!(
            r#"
        http get -e -f {url} | $"($in.status) => ($in.body)"
        "#,
            url = server.url()
        )
        .as_str()
    ));

    assert!(actual.out.contains("400 => error body"))
}

#[test]
fn http_get_with_accept_errors_and_full_json_response() {
    let mut server = Server::new();

    let _mock = server
        .mock("GET", "/")
        .with_status(400)
        .with_header("content-type", "application/json")
        .with_body(
            r#"
        {"msg": "error body"}
        "#,
        )
        .create();

    let actual = nu!(pipeline(
        format!(
            r#"
        http get -e -f {url} | $"($in.status) => ($in.body.msg)"
        "#,
            url = server.url()
        )
        .as_str()
    ));

    assert!(actual.out.contains("400 => error body"))
}

// These tests require network access; they use badssl.com which is a Google-affiliated site for testing various SSL errors.
// Revisit this if these tests prove to be flaky or unstable.

#[test]
fn http_get_expired_cert_fails() {
    let actual = nu!("http get https://expired.badssl.com/");
    assert!(actual.err.contains("network_failure"));
}

#[test]
fn http_get_expired_cert_override() {
    let actual = nu!("http get --insecure https://expired.badssl.com/");
    assert!(actual.out.contains("<html>"));
}

#[test]
fn http_get_self_signed_fails() {
    let actual = nu!("http get https://self-signed.badssl.com/");
    assert!(actual.err.contains("network_failure"));
}

#[test]
fn http_get_self_signed_override() {
    let actual = nu!("http get --insecure https://self-signed.badssl.com/");
    assert!(actual.out.contains("<html>"));
}