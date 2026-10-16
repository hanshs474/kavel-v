# kavel

Kavel is a free AI video generator and AI image generator — 4K clips with sound, and images you can run without an account or a card. This module calls it from V: one function, standard library only.

```v
import kavel

fn main() {
	url := kavel.generate('a paper-cut fox in a moonlit forest')!
	println(url) // https://cdn.kavel.ai/uploads/…/….webp
}
```

No key is needed for a first try: the call runs on Kavel's free allowance.

```sh
v install hanshs474.kavel
```

## Past the free allowance

Create an API key on your Kavel account at https://www.kavel.ai/settings/apikeys and pass it (or set `KAVEL_API_KEY`):

```v
url := kavel.generate('isometric tiny greenhouse', api_key: os.getenv('KAVEL_API_KEY'), model: 'gpt-image-2')!
```

With a key the call runs on your account: your credits, and the image models your [plan](https://www.kavel.ai/pricing?utm_source=vpm) includes. Every failure comes back as an error with a readable reason — spent allowance, refused prompt, wrong key or timeout.

## More from Kavel

Editing a photo instead of starting from a prompt? Kavel keeps a page per edit — [hairstyle](https://www.kavel.ai/image/ai-hairstyle-changer?utm_source=vpm), [outfit](https://www.kavel.ai/image/ai-outfit-generator?utm_source=vpm) and the rest under [AI image tools](https://www.kavel.ai/image?utm_source=vpm). Video lives under [AI video tools](https://www.kavel.ai/video?utm_source=vpm).

MIT licensed.
