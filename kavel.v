// Module kavel generates an AI image with Kavel (https://www.kavel.ai) from V.
//
// Kavel is a free AI video generator and AI image generator. Without an API key a
// call runs on Kavel's free allowance (text to image). With a key — `api_key`, or the
// `KAVEL_API_KEY` environment variable — it runs on your Kavel account: your credits
// and the image models your plan includes.
module kavel

import net.http
import net.urllib
import os
import rand
import time
import x.json2

pub const base_url = 'https://www.kavel.ai'
pub const keys_url = 'https://www.kavel.ai/settings/apikeys'
const free_model = 'kavel-image-v1'
const user_agent = 'kavel-v/0.1.0'

@[params]
pub struct Options {
pub:
	api_key       string
	model         string
	aspect_ratio  string = '1:1'
	timeout_sec   int    = 360
	poll_every_ms int    = 5000
}

fn call(method http.Method, url string, body string, key string, anon string) map[string]json2.Any {
	mut header := http.new_header(key: .content_type, value: 'application/json')
	header.add(.user_agent, user_agent)
	if key != '' {
		header.add(.authorization, 'Bearer ${key}')
	} else {
		header.add_custom('x-anon-id', anon) or {}
	}
	resp := http.fetch(http.FetchConfig{
		url:    url
		method: method
		header: header
		data:   body
	}) or { return {
		'code':    json2.Any(-1)
		'message': json2.Any('network error: ${err}')
	} }
	parsed := json2.decode[json2.Any](resp.body) or {
		return {
			'code':    json2.Any(-1)
			'message': json2.Any('unexpected reply from Kavel (HTTP ${resp.status_code})')
		}
	}
	return parsed.as_map()
}

fn code_of(m map[string]json2.Any) int {
	return (m['code'] or { json2.Any(-1) }).int()
}

// generate returns the URL of one generated image, or an error with a readable reason.
pub fn generate(prompt string, opts Options) !string {
	text := prompt.trim_space()
	if text == '' {
		return error('write a prompt first')
	}
	key := if opts.api_key != '' { opts.api_key } else { os.getenv('KAVEL_API_KEY') }
	anon := 'v-${rand.hex(16)}'
	model := if key != '' && opts.model != '' { opts.model } else { free_model }
	body := '{"provider":"kie","mediaType":"image","model":${json2.encode(model)},"scene":"text-to-image","prompt":${json2.encode(text)},"options":{"aspect_ratio":${json2.encode(opts.aspect_ratio)}}}'
	submit := call(.post, '${base_url}/api/ai/generate', body, key, anon)
	if code_of(submit) != 0 {
		return error((submit['message'] or { json2.Any('request refused') }).str())
	}
	data := (submit['data'] or { json2.Any(map[string]json2.Any{}) }).as_map()
	if (data['wall'] or { json2.Any(false) }).bool() {
		return error('the free allowance is spent - pass an API key from ${keys_url}')
	}
	task := (data['id'] or { json2.Any('') }).str()
	if task == '' {
		return error('Kavel returned no task id')
	}
	deadline := time.now().add_seconds(opts.timeout_sec)
	for time.now() < deadline {
		time.sleep(opts.poll_every_ms * time.millisecond)
		env := if key != '' {
			call(.post, '${base_url}/api/ai/query', '{"taskId":${json2.encode(task)}}', key, anon)
		} else {
			call(.get,
				'${base_url}/api/ai/anon-query?taskId=${urllib.query_escape(task)}&provider=kie&mediaType=image',
				'', '', anon)
		}
		if code_of(env) != 0 {
			continue // a dropped poll is not a failed generation
		}
		d := (env['data'] or { continue }).as_map()
		if (d['status'] or { json2.Any('') }).str() == 'failed' {
			return error('generation failed - try another prompt')
		}
		for field in ['cleanImages', 'images'] {
			imgs := (d[field] or { continue }).as_array()
			if imgs.len > 0 {
				first := imgs[0]
				m := first.as_map()
				if 'url' in m {
					return (m['url'] or { json2.Any('') }).str()
				}
				return first.str()
			}
		}
	}
	return error('still running after ${opts.timeout_sec} seconds (task ${task})')
}
