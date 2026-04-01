#!/usr/bin/env python3
"""
AI Provider Interface
Handles connections to various AI video generation services.
"""

import os
import time
import json
import requests
from pathlib import Path
from typing import Optional, Dict, Any
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'shared-utils'))
from api_key_utils import find_api_key


class AIProvider:
    """Unified interface for AI video generation providers."""
    
    def __init__(self, provider_name: str, config: Dict[str, Any]):
        """
        Initialize AI provider.
        
        Args:
            provider_name: Name of provider (kieai, runway, pika, etc.)
            config: Configuration dict with API keys and endpoints
        """
        self.provider = provider_name.lower()
        self.config = config.get(provider_name, {})

        # API key policy:
        # - KIE.ai uses KIE_API_KEY (preferred). KIEAI_API_KEY is accepted as a fallback.
        # - Other providers use {PROVIDER}_API_KEY (for example RUNWAY_API_KEY).
        self.api_key = self.config.get('api_key')
        if not self.api_key:
            if self.provider == 'kieai':
                self.api_key = os.getenv('KIE_API_KEY') or os.getenv('KIEAI_API_KEY')
            else:
                self.api_key = os.getenv(f'{provider_name.upper()}_API_KEY')

        self.endpoint = self.config.get('endpoint', self._default_endpoint())
        
    def _default_endpoint(self) -> str:
        """Get default endpoint for provider."""
        endpoints = {
            'kieai': 'https://api.kie.ai/v1',
            'runway': 'https://api.runwayml.com/v1',
            'pika': 'https://api.pika.art/v1',
            'stability': 'https://api.stability.ai/v2beta',
            'mock': None
        }
        return endpoints.get(self.provider, 'https://api.kie.ai/v1')
    
    def generate_video(self, prompt: str, duration: int = 5, 
                       resolution: str = "1080p", style: str = "cinematic",
                       output: Optional[Path] = None, **kwargs) -> Path:
        """
        Generate video from text prompt.
        
        Args:
            prompt: Text description
            duration: Video length in seconds
            resolution: Output resolution
            style: Visual style
            output: Output file path
            **kwargs: Additional provider-specific options
            
        Returns:
            Path to generated video
        """
        if self.provider == 'kieai':
            return self._generate_kieai(prompt, duration, resolution, style, output, **kwargs)
        elif self.provider == 'runway':
            return self._generate_runway(prompt, duration, resolution, style, output, **kwargs)
        elif self.provider == 'pika':
            return self._generate_pika(prompt, duration, resolution, style, output, **kwargs)
        elif self.provider == 'mock':
            return self._generate_mock(prompt, duration, resolution, style, output, **kwargs)
        else:
            raise ValueError(f"Unknown provider: {self.provider}")
    
    def _generate_kieai(self, prompt, duration, resolution, style, output, **kwargs):
        """Generate video using KIE.AI API."""
        if not self.api_key:
            raise ValueError("KIE_API_KEY not configured (set it in your environment to use provider=kieai)")
        
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json'
        }
        
        # Map resolution to dimensions
        res_map = {"720p": (1280, 720), "1080p": (1920, 1080), "4k": (3840, 2160)}
        width, height = res_map.get(resolution, (1920, 1080))
        
        payload = {
            'prompt': prompt,
            'duration': duration,
            'width': width,
            'height': height,
            'style': style,
            'seed': kwargs.get('seed'),
            'negative_prompt': kwargs.get('negative_prompt')
        }
        
        # Remove None values
        payload = {k: v for k, v in payload.items() if v is not None}
        
        try:
            # Submit generation job
            response = requests.post(
                f"{self.endpoint}/video/generate",
                headers=headers,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            result = response.json()
            
            job_id = result.get('job_id') or result.get('id')
            print(f"   Job submitted: {job_id}")
            
            # Poll for completion
            return self._poll_job(job_id, headers, output)
            
        except requests.RequestException as e:
            raise RuntimeError(f"KIE.AI API error: {e}")
    
    def _generate_runway(self, prompt, duration, resolution, style, output, **kwargs):
        """Generate video using Runway ML API."""
        if not self.api_key:
            raise ValueError("Runway API key not configured")
        
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json'
        }
        
        res_map = {"720p": "720p", "1080p": "1080p", "4k": "4k"}
        
        payload = {
            'prompt': prompt,
            'duration': duration,
            'resolution': res_map.get(resolution, "1080p"),
            'style': style
        }
        
        try:
            response = requests.post(
                f"{self.endpoint}/video",
                headers=headers,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            result = response.json()
            
            job_id = result.get('id')
            return self._poll_job(job_id, headers, output)
            
        except requests.RequestException as e:
            raise RuntimeError(f"Runway API error: {e}")
    
    def _generate_pika(self, prompt, duration, resolution, style, output, **kwargs):
        """Generate video using Pika Labs API."""
        if not self.api_key:
            raise ValueError("Pika API key not configured")
        
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json'
        }
        
        payload = {
            'prompt': prompt,
            'video_length': duration,
            'aspect_ratio': '16:9' if resolution != 'vertical' else '9:16',
            'style': style
        }
        
        try:
            response = requests.post(
                f"{self.endpoint}/videos",
                headers=headers,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            result = response.json()
            
            job_id = result.get('id')
            return self._poll_job(job_id, headers, output)
            
        except requests.RequestException as e:
            raise RuntimeError(f"Pika API error: {e}")
    
    def _generate_mock(self, prompt, duration, resolution, style, output, **kwargs):
        """Generate a mock video for testing without API calls."""
        print("   Using mock provider (no API call)")
        
        # Create a simple colored video with text using MoviePy
        try:
            from moviepy.editor import ColorClip, TextClip, CompositeVideoClip
            
            res_map = {"720p": (1280, 720), "1080p": (1920, 1080), "4k": (3840, 2160)}
            width, height = res_map.get(resolution, (1920, 1080))
            
            # Create gradient background
            bg = ColorClip(size=(width, height), color=(30, 30, 60)).set_duration(duration)
            
            # Add animated text
            text_content = f"MOCK VIDEO\n\nPrompt:\n{prompt[:150]}"
            text = TextClip(
                text_content,
                fontsize=36,
                color='white',
                size=(width - 100, None),
                method='caption',
                align='center',
                font='Arial-Bold'
            ).set_duration(duration).set_position('center')
            
            # Add style label
            style_text = TextClip(
                f"Style: {style} | Duration: {duration}s",
                fontsize=24,
                color='yellow'
            ).set_duration(duration).set_position(('center', height - 100))
            
            video = CompositeVideoClip([bg, text, style_text])
            video.write_videofile(str(output), fps=30, codec='libx264', audio=False, verbose=False)
            video.close()
            
            return output
            
        except ImportError:
            raise RuntimeError("MoviePy required for mock generation")
    
    def _poll_job(self, job_id: str, headers: dict, output: Path, 
                  max_attempts: int = 60, delay: int = 5) -> Path:
        """
        Poll for job completion and download result.
        
        Args:
            job_id: Job identifier
            headers: Request headers
            output: Output file path
            max_attempts: Maximum poll attempts
            delay: Seconds between polls
            
        Returns:
            Path to downloaded video
        """
        for attempt in range(max_attempts):
            time.sleep(delay)
            
            try:
                status_resp = requests.get(
                    f"{self.endpoint}/jobs/{job_id}",
                    headers=headers,
                    timeout=30
                )
                status_resp.raise_for_status()
                status = status_resp.json()
                
                state = status.get('status') or status.get('state')
                print(f"   Status: {state} (attempt {attempt + 1}/{max_attempts})")
                
                if state in ('completed', 'done', 'success'):
                    video_url = status.get('video_url') or status.get('output_url')
                    if video_url:
                        return self._download_video(video_url, output)
                    raise RuntimeError("No video URL in completed job")
                    
                elif state in ('failed', 'error'):
                    error_msg = status.get('error', 'Unknown error')
                    raise RuntimeError(f"Generation failed: {error_msg}")
                    
            except requests.RequestException as e:
                print(f"   Poll error: {e}")
                continue
        
        raise RuntimeError(f"Job polling timeout after {max_attempts} attempts")
    
    def _download_video(self, url: str, output: Path) -> Path:
        """Download video from URL."""
        print(f"   Downloading video...")
        
        response = requests.get(url, stream=True, timeout=120)
        response.raise_for_status()
        
        with open(output, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        print(f"   Downloaded: {output}")
        return output
    
    def image_to_video(self, image_path: Path, prompt: str = None,
                       duration: int = 5, **kwargs) -> Path:
        """
        Animate an image into video.
        
        Args:
            image_path: Path to input image
            prompt: Optional motion description
            duration: Video length
            **kwargs: Additional options
            
        Returns:
            Path to generated video
        """
        # Implementation varies by provider
        if self.provider == 'kieai':
            return self._image_to_video_kieai(image_path, prompt, duration, **kwargs)
        elif self.provider == 'runway':
            return self._image_to_video_runway(image_path, prompt, duration, **kwargs)
        else:
            # Fallback: Use MoviePy for image animation
            return self._image_to_video_local(image_path, prompt, duration, **kwargs)
    
    def _image_to_video_local(self, image_path, prompt, duration, **kwargs):
        """Create video from image using MoviePy effects."""
        from moviepy.editor import ImageClip
        
        motion = kwargs.get('motion', 'ken_burns')
        
        clip = ImageClip(str(image_path))
        
        if motion == 'zoom':
            # Zoom in effect
            clip = clip.resize(lambda t: 1 + 0.2 * t / duration).set_duration(duration)
        elif motion == 'ken_burns':
            # Pan and zoom
            from moviepy.editor import vfx
            clip = clip.resize(1.2).set_duration(duration)
            clip = vfx.scroll(clip, w=clip.w*0.1, h=clip.h*0.05, x_speed=10, y_speed=5)
        else:
            clip = clip.set_duration(duration)
        
        output = kwargs.get('output', image_path.stem + '_video.mp4')
        clip.write_videofile(str(output), fps=30, codec='libx264')
        clip.close()
        
        return Path(output)