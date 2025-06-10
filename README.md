# Shots Studio

**AI-powered screenshot management. Searchable. Organized. Decluttered.**

Shots Studio turns your chaotic screenshot gallery into an intelligent, organized archive. Backed by powerful AI, it makes your screenshots searchable, taggable, and easy to browse — all while giving you control.

---

## What is Shots Studio?

Drowning in screenshots you can’t find when you need them?
**Shots Studio** solves that by bringing **AI-driven search, smart tagging, and seamless organization** to your screenshot collection.

With Shots Studio, you can:

* **Search** your screenshots by content — not just filename.
* Add or generate **tags** automatically using AI.
* Group related screenshots into custom **collections**.

---

## Key Features

* **AI-Powered Search**
  Search screenshots by the **text**, **objects**, or **topics** they contain — even if they were never manually labeled.

* **Smart Tagging**
  Let AI suggest relevant tags or add your own to keep your gallery tidy and context-rich.

* **Organize into Collections**
  Group related screenshots into named collections for effortless navigation.

* **Choose Your AI**
  Pick between **Gemini 2.0 Flash** for speed or **Gemini 2.5 Pro** for deeper analysis. You control the power.

* **Open Source**
  Built with transparency and community in mind. Explore the code. Contribute. Make it yours.

---

## How It Works + Privacy

Shots Studio sends your screenshot data (images or extracted text) to **Google’s Gemini API** for AI-powered processing.

We never store your data. For more about how your data is handled, check out the [Gemini API privacy policy](https://ai.google.dev/gemini-api/terms).

---

## Why Shots Studio?

* **Declutter your gallery**
  No more endless scrolling to find that one screenshot.

* **Instant access to information**
  Search and filter screenshots just like you would search your notes.

* **Customizable AI power**
  You decide what model to use — optimize for speed or accuracy.

* **Built by the community**
  It’s open-source and community-driven, not a black box.

---

## Getting Started

Follow these steps to get Shots Studio up and running:

1. **Get a Gemini API key**  
   Visit https://ai.google.dev/gemini-api/docs/api-key and sign in with your Google account to generate an API key.

2. **Download & install the APK**  
   - Go to the **Releases** page of this repo and download the latest `*.apk`.  
   - On your Android device, enable “Install from unknown sources” (or “Install unknown apps”) for your browser or file manager.  
   - Open the downloaded APK to install Shots Studio.

3. **Grant permissions**  
   When you first launch the app, allow access to your device’s storage so Screenshots can be discovered and processed.

4. **Configure your API key**  
   - Tap the ☰ menu icon (top-left) and choose **Settings** → **API Key** (or just **API Key**).  
   - Paste in the Gemini key you obtained in step 1 and save.

5. **Process screenshots**  
   Tap the AI ⚡️ button (top-right) to start analyzing your screenshots. The app will extract text, detect objects/topics, and suggest tags.

6. **(Optional) Auto-add to collections**  
   If you’d like AI to populate a collection automatically:  
   - Create a new collection  
   - Toggle **Auto-Add** on  
   All new screenshots matching that collection’s criteria will be added automatically.

That’s it! You can now search, tag and browse your screenshots with AI-powered superpowers.

---


## Contributing

We welcome your help! Whether it’s code, bug reports, feature ideas, or documentation — we’d love your input.
Start by checking out `CONTRIBUTING.md` or opening an issue/pull request.

## Setting Up Git Hooks

This project uses Git hooks to automate certain tasks (e.g., version bumping). To enable these hooks in your local clone, please run the following command from the root of the repository after cloning:

```bash
git config core.hooksPath scripts/git-hooks
```

This only needs to be done once per clone.
