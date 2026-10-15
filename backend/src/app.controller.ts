import { Controller, Get, Redirect } from '@nestjs/common';
import { AppService } from './app.service';
import { Public } from './common/public.decorator';

// Where people who open the API address in a browser are sent.
const WEB_APP_URL =
  process.env.WEB_APP_URL ?? 'https://taraaz.github.io/-mesmerapp/';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Public()
  @Get()
  @Redirect(WEB_APP_URL, 302)
  openWebApp() {}

  // Liveness check used by the hosting platform.
  @Public()
  @Get('health')
  getHello(): string {
    return this.appService.getHello();
  }
}
