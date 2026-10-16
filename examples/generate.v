import kavel

fn main() {
	if url := kavel.generate('') {
		println('FAIL: empty prompt accepted ${url}')
	} else {
		println('ok: ${err}')
	}
	url := kavel.generate('a paper-cut fox in a moonlit forest') or {
		println('kavel: ${err}')
		return
	}
	println(url)
}
